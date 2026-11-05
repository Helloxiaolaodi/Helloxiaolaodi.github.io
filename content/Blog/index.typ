#import "../index.typ": template, tufted
#show: template.with(
  title: "Blog",
  description: "Some blog examples",
)

= 博客 / Blog

中文博客样例可参考 #link("https://yousa-mirage.github.io/Blog")[我的个人网站]。

== 2026

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

== 2025

#tufted.blog-entry(
  date: datetime(year: 2025, month: 10, day: 30),
  path: "2025-10-30-normal-distribution/",
  title: "Normal Distribution",
)
#tufted.blog-entry(
  date: datetime(year: 2025, month: 4, day: 16),
  path: "2025-04-16-monkeys-apes",
  title: "Monkeys vs Apes",
)

== 2024

#tufted.blog-entry(
  date: "2024-10-04",
  path: "2024-10-04-iterators-generators/",
  title: "Iterators vs Generators in Python",
)
