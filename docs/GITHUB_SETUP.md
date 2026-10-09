# GitHub 发布

本库适合直接 Fork。发布自己的版本时，只提交源码、文档、占位图和构建脚本，不提交本地记录、`.build/`、`dist/` 或压缩包。

## 使用 GitHub 网页

1. 打开 `lvzhi_companiontemplates`，点击 **Fork**。
2. 选择自己的账号，确认仓库名和可见性。
3. 在 fork 中替换文案、标识和图片，再提交到自己的分支。
4. 构建通过后，在 GitHub Releases 上传对应平台的 zip；不要把成品包提交到 Git 历史。

## 使用命令行

```sh
git clone https://github.com/<你的用户名>/lvzhi_companiontemplates.git
cd lvzhi_companiontemplates
git checkout -b customize/<你的代号>
git add .
git commit -m "Customize generic companion template"
git push -u origin customize/<你的代号>
```

公开发布前确认所有人物图片、字体、图标和文案拥有再分发授权。每个公开版本创建独立标签，例如 `v0.1.4-template`，并在 Release 中说明 macOS/Windows 的构建结果、权限要求和已知限制。
