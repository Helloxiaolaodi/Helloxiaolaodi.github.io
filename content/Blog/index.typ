#import "../index.typ": template, tufted
#show: template.with(
  title: "博客",
  description: "科研笔记、骑行日志与生活随笔。",
  lang: "zh",
)

= 博客

== 2026

#tufted.blog-entry(
  date: datetime(year: 2026, month: 10, day: 28),
  path: "2026-10-28-typst-guide/",
  title: "科研利器之 Typst 的安装与使用",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 8, day: 22),
  path: "2026-08-22-outline-deploy/",
  title: "Outline 部署、使用与备份下载",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 8, day: 8),
  path: "2026-08-08-lucuro-deploy/",
  title: "Lucuro 仓库部署解读",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 8, day: 5),
  path: "2026-08-05-quarto-guide/",
  title: "科研利器之 Quarto 的安装与使用",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 8, day: 1),
  path: "2026-08-01-galibierhub-deploy/",
  title: "GalibierHub 网站部署详细解读",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 7, day: 18),
  path: "2026-07-18-bioinfo-tools/",
  title: "科研利器之生信工具的原理合集",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 7, day: 17),
  path: "2026-07-17-server-git/",
  title: "科研江湖之服务器的 Git 使用",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 7, day: 6),
  path: "2026-07-06-zotero-hugo-deploy/",
  title: "科研江湖之 Zotero-Hugo 文献库部署秘笈",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 7, day: 3),
  path: "2026-07-03-server-shell-setup/",
  title: "科研江湖之服务器的界面设置方案",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 27),
  path: "2026-06-27-android-open-source-tools/",
  title: "Android 开源江湖兵器谱",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 14),
  path: "2026-06-14-rebased-guide/",
  title: "科研江湖之 Rebased 版本控制秘笈",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 8),
  path: "2026-06-08-tool-arsenal/",
  title: "科研江湖之绝世兵器谱",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 7),
  path: "2026-06-07-cycling-log/",
  title: "菜鸟杨三多江湖行纪：单骑七千里，一蓑烟雨任平生",
)

#tufted.blog-entry(
  date: datetime(year: 2026, month: 6, day: 6),
  path: "2026-06-06-linux-command-guide/",
  title: "生信常用命令速查：Linux / Conda / Slurm / QIIME 2 / R / Python / Git",
)
