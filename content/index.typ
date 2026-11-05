#import "../config.typ": template, tufted
#show: template

// tufted.margin-note 可以让你在边栏中放置内容
// 宽大的边栏是 tufte 样式的特点，将注释放于其中并与正文并排，便于对照
#tufted.margin-note({
  image("imgs/home-photo-1.jpg")
  image("imgs/home-photo-2.jpg")
})

#tufted.margin-note[
  杨三多（Helloxiaolaodi）\
  研究生在读 · 骑行爱好者 · 上过班的人
]
#tufted.margin-note[
  Yang Sanduo (Helloxiaolaodi) \
  Master's student · Cycling enthusiast · Someone who has worked a 9-to-5.
]

= 杨三多

研究生在读。日常在实验室里与文献、数据和代码周旋，偶尔抬头，发现窗外天气正好。

骑行爱好者。车轮碾过齐鲁大地、江南水乡与塞外雪山，也碾过城市通勤路上的每一道裂缝。单车是我丈量世界的方式，也是我给自己留的一条退路。

上过班的人。知道早高峰地铁的拥挤，也体会过下班后还要挤时间训练、写东西的滋味。正因为上过班，才更清楚自己想过的生活长什么样。

#figure(caption: "杨三多 · Helloxiaolaodi")[#image("imgs/profile.jpg", width: 420pt)]

这里是我的个人网站，用来存放科研笔记、骑行日志和一些没处安放的生活碎片。欢迎随便逛逛。

== 关于这个网站

- #link("/Blog/")[博客]：科研笔记、骑行日志与生活随笔。
- #link("/CV/")[简历]：教育背景、赛事经历与作品。
- #link("/Docs/")[文档]：Typst 与本站的搭建说明。

如果你也有想记录的江湖，不妨从这里开始。
