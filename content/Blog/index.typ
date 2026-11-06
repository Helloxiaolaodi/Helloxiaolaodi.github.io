#import "../index.typ": template, tufted
#show: template.with(
  title: "博客",
  description: "科研笔记、骑行日志与生活随笔。",
  lang: "zh",
)

= 博客

== 2026

#tufted.blog-entry(
  date: datetime(year: 2026, month: 11, day: 6),
  path: "2026-11-06-linux-command-guide/",
  title: "生信常用命令速查：Linux / Conda / Slurm / QIIME 2 / R / Python / Git",
)
#tufted.blog-entry(
  date: datetime(year: 2026, month: 11, day: 5),
  path: "2026-11-05-cycling-log/",
  title: "菜鸟杨三多江湖行纪：骑行日志（2023–2024）",
)
#tufted.blog-entry(
  date: datetime(year: 2026, month: 10, day: 28),
  path: "2026-10-28-typst-guide/",
  title: "科研利器之 Typst 的安装与使用",
)
