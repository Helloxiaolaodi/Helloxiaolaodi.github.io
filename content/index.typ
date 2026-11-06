#import "../config.typ": template, tufted
#show: template.with(lang: "ko")

// tufted.margin-note 可以让你在边栏中放置内容
// 宽大的边栏是 tufte 样式的特点，将注释放于其中并与正文并排，便于对照
#tufted.margin-note({
  image("imgs/home-photo-1.jpg")
  image("imgs/home-photo-2.jpg")
})

#tufted.margin-note[
  杨三多（Helloxiaolaodi）\
  대학원 재학 · 라이딩 애호가 · 직장 생활을 해본 사람
]
#tufted.margin-note[
  Yang Sanduo (Helloxiaolaodi) \
  대학원생 · 자전거 애호가 · 회사 생활을 경험한 사람
]

= 杨三多

대학원 재학 중입니다. 하루의 대부분을 실험실에서 논문과 데이터, 코드와 씨름하며 보내다가, 문득 고개를 들면 창밖 날씨가 좋다는 걸 발견하곤 합니다.

라이딩 애호가입니다. 바퀴는 치루 땅과 강남의 물길, 변방의 설산을 지나왔고, 도시 출퇴근길의 갈라진 아스팔트도 지나왔습니다. 자전거는 제가 세상을 재는 방식이자, 스스로에게 남겨둔 마지막 도피처입니다.

직장 생활을 해본 사람입니다. 출근길 지하철의 혼잡을 알고, 퇴근 후에도 시간을 쪼개 훈련하고 글을 써야 했던 맛도 압니다. 그래서인지 제가 어떤 삶을 살고 싶은지 조금 더 선명하게 압니다.

#figure(caption: "杨三多 · Helloxiaolaodi")[#image("imgs/profile.jpg", width: 420pt)]

여기는 제 개인 웹사이트입니다. 연구 노트, 라이딩 기록, 그리고 어디에도 담기 어려운 삶의 조각들을 모아둡니다. 편하게 둘러보세요.

== 이 웹사이트에 대하여

- #link("/Blog/")[블로그]: 연구 노트, 라이딩 기록과 일상 에세이.
- #link("/CV/")[이력서]: 학력, 대회 경력과 작업물.
- #link("/Docs/")[문서]: Typst와 이 사이트의 구축 안내.

당신에게도 기록하고 싶은 강호가 있다면, 여기서 시작해보세요.
