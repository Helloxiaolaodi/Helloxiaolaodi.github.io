# 构建 / 部署后的清理规则

本文档说明本站（Tufted-Blog-Template + Typst）每次构建、部署后会产生哪些**可再生、可安全删除**的文件，以及哪些文件**绝对不能删除或改动**。

> 核心原则：**只有构建产物可以删，源文件一律不动。**
> 判断方法很简单——如果删掉之后运行 `python build.py build -f` 能重新生成，它就是构建产物；如果删掉后内容就丢了、网站就坏了，它就是源文件。

---

## 一、每次构建后可以删除的文件 / 目录

### 1. 构建输出目录

| 路径 | 说明 |
| --- | --- |
| `_site/` | **整个网站的输出目录**，包含 `index.html`、各页面 HTML、`feed.xml`、`sitemap.xml`、`robots.txt`、复制过去的 `assets/` 和内容图片。每次构建都会重新生成，删除后不影响源码，也不影响 GitHub Pages（CI 会重新构建）。 |
| `_site/**/*.html` | 由 `content/**/*.typ` 编译生成，可随时重建。 |
| `_site/assets/` | 从仓库根目录 `assets/` 复制而来，可重建。 |
| `_site/imgs/`、`_site/Blog/**/imgs/` | 从 `content/` 下的源图片复制而来，可重建。 |
| `_site/feed.xml`、`_site/sitemap.xml`、`_site/robots.txt` | 构建时自动生成的站点元数据文件。 |
| `_site/CV/CV-PDF.pdf` | 由 `content/CV/CV-PDF.typ` 自动编译出的 PDF，可重建。 |

**推荐清理方式：**

```bash
python build.py clean      # 仅清空 _site/ 内容（官方命令，最安全）
# 或者直接整目录删除：
rm -rf _site
```

### 2. 缓存与临时文件

| 类型 / 路径 | 说明 |
| --- | --- |
| `__pycache__/` | Python 字节码缓存。 |
| `*.pyc`、`*.pyo`、`*.py[cod]`、`*$py.class` | Python 编译缓存。 |
| `*.tmp` | 编辑器 / 脚本临时文件。 |
| `*.bak` | 备份文件。 |
| `*.log` | 日志文件。 |
| `.DS_Store` | macOS 目录元数据。 |
| `Thumbs.db` | Windows 缩略图缓存。 |
| `target/` | 历史构建残留目录（如存在）。 |
| `tufted-lib/*.pdf` | 模板库目录下被编译出来的 PDF 副本（如存在）。 |

**推荐清理方式：**

```bash
rm -rf __pycache__ target
find . -name "*.tmp" -o -name "*.bak" -o -name "*.log" | xargs -r rm -f
find . -name ".DS_Store" -o -name "Thumbs.db" | xargs -r rm -f
```

### 3. 本地环境（不是垃圾，但不要提交）

| 路径 | 说明 |
| --- | --- |
| `.venv/` | 本地 Python 虚拟环境，可删可重建，**不要提交到 Git**。 |
| `uv.lock` | 已被 `.gitignore` 忽略（如需锁定依赖再单独处理）。 |

---

## 二、绝对不能删除或改动的文件 / 目录

以下文件是网站的**唯一数据来源**，删除或随意修改会导致内容丢失、构建失败或部署失败。`_site/` 里的东西全部可再生，但这些不是。

### 1. 页面内容（源文件）

| 路径 | 说明 |
| --- | --- |
| `content/**/*.typ` | 所有页面的 Typst 源文件：`content/index.typ`、`content/Blog/index.typ`、`content/Blog/2026-10-28-typst-guide/index.typ`、`content/Blog/2026-11-05-cycling-log/index.typ`、`content/CV/index.typ`、`content/CV/CV-PDF.typ`、`content/Docs/**`。**这是文章正文，删了就要重写。** |
| `content/**/imgs/**` | 所有正文图片的**原始文件**，例如 `content/imgs/profile.jpg`、`content/imgs/home-photo-1.jpg`、`content/Blog/**/imgs/*.jpg`。删掉后网页图片会全部失效，且无法重新生成。 |
| `content/**` 下的其他资源 | 如 `.bib`、`.csv`、字体等，构建时会被引用或复制。 |

### 2. 模板与配置

| 路径 | 说明 |
| --- | --- |
| `config.typ` | 全站配置：站点标题、作者、语言、导航栏、页眉页脚、RSS 目录。**必须保留，且修改前想清楚。** |
| `tufted-lib/**` | 模板库核心代码（`tufted.typ`、样式等）。**不要改、不要删**，除非明确要升级模板。 |
| `assets/**` | 全站静态资源源文件：`assets/*.css`、`assets/icons/*.svg`、`assets/scripts/*.js`。**是源文件，不是 `_site/assets/` 里的副本。** |
| `build.py` | 构建脚本。除非要改构建逻辑，否则不要动。 |
| `.github/workflows/deploy.yml` | GitHub Pages 自动部署工作流；删了网站就不会自动发布。 |
| `.github/workflows/update.yml` | 定时更新 / 相关自动化工作流。 |

### 3. 工程基础文件

| 路径 | 说明 |
| --- | --- |
| `.git/` | Git 仓库历史。**绝对不要删除**。 |
| `.gitignore` | 定义哪些文件不进入版本库（`_site/`、缓存等）。删了会导致构建垃圾被提交。 |
| `README.md`、`README_en.md` | 模板使用说明，保留备查。 |
| `LICENSE` | 开源许可证，**不要删除或修改**。 |
| `CHANGELOG.md`、`CHANGELOG_en.md` | 模板更新记录，建议保留。 |
| `.vscode/settings.json` | 团队 / 本地编辑器配置（如存在）。 |

### 4. 特别提醒

- **不要手动编辑 `_site/` 里的任何文件**：它们每次构建都会被覆盖，改了也会丢。要改内容，改 `content/` 下的源文件后重新构建。
- **不要把 `_site/` 提交到 Git**：它已在 `.gitignore` 中。GitHub Actions 会在云端用源码重新构建并发布。
- **不要重命名仓库或修改 Pages 源设置**：本站使用根绝对路径（`/assets/...`、`/Blog/`），仓库必须保持为 `Helloxiaolaodi.github.io`，Pages 源必须保持 "GitHub Actions"，否则样式和子页面会 404。
- **不要在构建过程中删除 `content/` 下的图片**：即使 `_site/` 里已有副本，源图片才是唯一可再生的来源。

---

## 三、标准构建 / 部署流程

```bash
# 1. 全量重建（自动清理 + 编译 + 复制资源）
python build.py build -f

# 2. 本地预览检查
python build.py preview

# 3. 提交源码（只提交 content/、config.typ、assets/ 等源文件）
git add content config.typ assets
git commit -m "..."
git push

# 4. push 后 GitHub Actions 自动构建并部署，无需上传 _site/
```

部署完成后如需清理本地垃圾：

```bash
rm -rf _site __pycache__ target
find . -name "*.tmp" -o -name "*.bak" -o -name "*.log" | xargs -r rm -f
```

---

## 四、快速判断清单

构建完成后，逐项自检：

- [ ] `_site/` 是本次新生成的，且**没有**被 `git add`
- [ ] `content/**/*.typ` 和 `content/**/imgs/**` 完整无缺
- [ ] `config.typ`、`build.py`、`tufted-lib/`、`assets/` 未被误删或误改
- [ ] `.github/workflows/` 下的 YAML 仍在
- [ ] `__pycache__/`、`*.log`、`*.tmp` 等临时文件已清理
- [ ] `git status` 中只剩你**有意修改**的源文件
