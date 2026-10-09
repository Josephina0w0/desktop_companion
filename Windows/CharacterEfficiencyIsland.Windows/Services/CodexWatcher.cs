using CharacterEfficiencyIsland.Windows.Core;
using System.IO;
using Microsoft.Data.Sqlite;

namespace CharacterEfficiencyIsland.Windows.Services;

internal sealed class CodexWatcher
{
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private readonly AppState _state;
    private readonly string _databasePath;
    private HashSet<string> _knownTurns = new(StringComparer.Ordinal);
    private bool _seeded;
    private bool _polling;

    public CodexWatcher(AppState state)
    {
        _state = state;
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        _databasePath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".codex",
            "thread_history_1.sqlite");
    }

    public async Task PollAsync()
    {
        if (_polling)
        {
            return;
        }
        _polling = true;
        try
        {
            if (!File.Exists(_databasePath))
            {
                _state.CodexStatus = "Codex 待启动：尚未找到本地任务记录";
                return;
            }

            var current = await Task.Run(ReadCompletedTurns);
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            if (!_seeded)
            {
                _knownTurns = current;
                _seeded = true;
                _state.CodexStatus = "Codex 已连接";
                return;
            }

            var added = current.Except(_knownTurns).Count();
            _knownTurns = current;
            _state.CodexStatus = "Codex 已连接";
            if (added > 0)
            {
                _state.RecordCodexCompletion(added);
            }
        }
        catch
        {
            _state.CodexStatus = "已找到 Codex，但暂时无法读取完成状态";
        }
        finally
        {
            _polling = false;
        }
    }

    private HashSet<string> ReadCompletedTurns()
    {
        var builder = new SqliteConnectionStringBuilder
        {
            DataSource = _databasePath,
            Mode = SqliteOpenMode.ReadOnly,
            Cache = SqliteCacheMode.Shared
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        };
        using var connection = new SqliteConnection(builder.ToString());
        connection.Open();
        using var command = connection.CreateCommand();
        command.CommandText = """
            select thread_id || ':' || turn_id
            from thread_turns
            where status = 'completed' and completed_at is not null
            order by completed_at desc
            limit 200;
            """;
        using var reader = command.ExecuteReader();
        var result = new HashSet<string>(StringComparer.Ordinal);
        while (reader.Read())
        {
            if (!reader.IsDBNull(0))
            {
                // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                result.Add(reader.GetString(0));
            }
        }
        return result;
    }
}
