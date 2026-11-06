#import "../index.typ": template, tufted
#show: template.with(
  title: "블로그",
  description: "연구 노트, 라이딩 기록과 일상 에세이.",
  lang: "ko",
)

= 블로그

== 2026

#tufted.blog-entry(
  date: datetime(year: 2026, month: 11, day: 5),
  path: "2026-11-05-cycling-log/",
  title: "초보 杨三多의 강호기행: 라이딩 일지 (2023–2024)",
)
#tufted.blog-entry(
  date: datetime(year: 2026, month: 10, day: 28),
  path: "2026-10-28-typst-guide/",
  title: "연구 필수 도구: Typst 설치와 사용 가이드",
)
