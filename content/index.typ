#import "../config.typ": template, tufted
#show: template.with(lang: "en")

// 侧栏照片（home-photo-1 已按要求缩小）
#tufted.margin-note({
  image("imgs/home-photo-1.jpg", width: 140pt)
  image("imgs/cycling-jiangxi-nanchang-jiujiang.jpg", width: 120pt)
  image("imgs/pbp2027-jiangxi-brm200-medal.jpg", width: 120pt)
})

#tufted.margin-note[
  Yang Sanduo (Helloxiaolaodi) \
  Graduate student · Cycling enthusiast · Ex-corporate
]

= Yang Sanduo

I am a graduate student. Most of my days go to wrestling with papers, data, and code in the lab — and every now and then I look up and notice how lovely the weather is outside the window.

I am a cycling enthusiast. My wheels have rolled across the Qilu plains, the waterways of Jiangnan, and the snow-capped mountains of the frontier; they have also crossed the cracked asphalt of the morning commute. To me a bicycle is both how I measure the world and the last refuge I keep for myself.

I have worked a corporate job. I know the crush of the early subway and the taste of carving out time to train and write after a full day. That is probably why I am a little clearer about the life I want to live.

#figure(image("imgs/profile.jpg", width: 420pt))

This is my personal website. I collect research notes, cycling records, and fragments of life that are hard to fit anywhere else. Feel free to look around.

== Lighting Up Jiangxi — 2026–2027 Cycling Check-in

From 2026 to 2027 I am riding the map of Jiangxi into light, one city at a time. So far: ① Nanchang, ② Jiujiang. (Across all my rides I have lit up 8 provinces and 35 cities so far.)

== About This Site

- #link("/Blog/")[Blog]: research notes, cycling logs, and everyday essays.
- #link("/CV/")[CV]: education, race history, and works.
- #link("/Docs/")[Docs]: guides to Typst and how this site is built.

If you also have a world worth recording, start here.

#line()

// 中文（折叠，点击展开）
#html.elem("details", attrs: (class: "lang-fold"), {
  html.elem("summary", [中文 · 点击展开 Chinese])
  [
    #tufted.margin-note[
      杨三多（Helloxiaolaodi）\
      在读研究生 · 骑行爱好者 · 有过职场经历
    ]

    我是一名在读研究生。大部分时间都在实验室里同论文、数据和代码较劲；偶尔抬起头，才发现窗外天气正好。

    我是一名骑行爱好者。车轮曾碾过齐鲁大地、江南水乡与边陲雪山，也碾过城市通勤路上开裂的柏油。自行车既是我丈量世界的方式，也是我留给自己的最后退路。

    我曾有过职场经历。体会过早班地铁的拥挤，也尝过下班后挤时间训练、写作的滋味。所以，对于自己想活成什么样，我比从前更清楚一些。

    这里是我的个人网站。收录研究笔记、骑行记录，以及一些难有归属的生活碎片。随意逛逛吧。

    == 点亮江西 · 2026–2027 单车骑行打卡

    2026 到 2027 年，我用单车一城一城地点亮江西地图。目前已完成：① 南昌市，② 九江市。（累计已点亮 8 省 35 市。）

    == 关于本站

    - #link("/Blog/")[博客]：研究笔记、骑行记录与日常随笔。
    - #link("/CV/")[简历]：教育经历、比赛经历与作品。
    - #link("/Docs/")[文档]：Typst 与本网站的搭建说明。

    如果你也有想记录的江湖，就从这里开始吧。
  ]
})

// 韩文（折叠，点击展开）
#html.elem("details", attrs: (class: "lang-fold"), {
  html.elem("summary", [한국어 · 펼치기 Korean])
  [
    #tufted.margin-note[
      杨三多（Helloxiaolaodi）\
      대학원 재학 · 라이딩 애호가 · 직장 생활을 해본 사람
    ]

    대학원 재학 중입니다. 하루의 대부분을 실험실에서 논문과 데이터, 코드와 씨름하며 보내다가, 문득 고개를 들면 창밖 날씨가 좋다는 걸 발견하곤 합니다.

    라이딩 애호가입니다. 바퀴는 치루 땅과 강남의 물길, 변방의 설산을 지나왔고, 도시 출퇴근길의 갈라진 아스팔트도 지나왔습니다. 자전거는 제가 세상을 재는 방식이자, 스스로에게 남겨둔 마지막 도피처입니다.

    직장 생활을 해본 사람입니다. 출근길 지하철의 혼잡을 알고, 퇴근 후에도 시간을 쪼개 훈련하고 써야 했던 맛도 압니다. 그래서인지 제가 어떤 삶을 살고 싶은지 조금 더 선명하게 압니다.

    여기는 제 개인 웹사이트입니다. 연구 노트, 라이딩 기록, 그리고 어디에도 담기 어려운 삶의 조각들을 모아둡니다. 편하게 둘러보세요.

    == 장시(江西) 점등 — 2026–2027 자전거 라이딩

    2026년부터 2027년까지 자전거로 도시를 하나씩 밟으며 장시성 지도를 '점등'하고 있습니다. 지금까지: ① 난창(南昌), ② 주장(九江). (지금까지 누적 8개 성, 35개 도시 점등.)

    == 이 웹사이트에 대하여

    - #link("/Blog/")[블로그]: 연구 노트, 라이딩 기록과 일상 에세이.
    - #link("/CV/")[이력서]: 학력, 대회 경력과 작업물.
    - #link("/Docs/")[문서]: Typst와 이 사이트의 구축 안내.

    당신에게도 기록하고 싶은 강호가 있다면, 여기서 시작해보세요.
  ]
})
