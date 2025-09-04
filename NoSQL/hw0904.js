
//movies 컬렉션에서 2010년 이상이고, 장르에 "Action"이 포함된 영화의 title, year, genres를 조회하세요.
db.movies.find({
  year: {$gte:2010},
  genres: "Action"
},{_id:0,title:1,year:1,genres:1}
)

//새로운 고객 "홍길동"을 users 컬렉션에 추가하세요.
//이메일은 "hong@test.com", 관심 장르는 ["Action", "Comedy"]입니다.
db.users.insertOne({
  name: "홍길동",
  email: "hong@test.com",
  interest:['Action','Comedy']
})

//comments 컬렉션에 "홍길동"이 "Action 영화 최고!"라는 댓글을 삽입하세요.
//이후 "홍길동"의 댓글 내용을 "Action 영화 진짜 재밌다!"로 수정하세요.

db.comments.insertOne({
  name:"홍길동",
  email:"hong@test.com",
  text:"Action 영화 최고!"
})

db.comments.updateOne(
  {name: "홍길동", text: "Action 영화 최고!"}, 
  {$set:{text:"Action 영화 진짜 재밌다!"}} 
)

//movies 컬렉션에서 장르별 영화 수를 집계하고, 가장 많은 3개 장르를 출력하세요.
db.movies.aggregate([
  {$unwind:"$genres"},
  {$group:{
    _id:"$genres",
    count:{$sum:1}
  }},
  {$sort:{count:-1}},
  {$limit:3}
])

//movies 컬렉션에서 평점이 8.5 이상인 영화의 title, imdb.rating, year를 출력하고, 최신 영화 순으로 정렬하세요.

db.movies.aggregate([
  {$match:{"imdb.rating":{$gte:8.5}}},
  {
    $project:{
      _id:0,title:1,title:1,rating:"$imdb.rating",year:1
    }
  },
  {$sort:{year:-1}}
])

//  comments에서 *사용자(email 기준)*별 총 댓글 수, 댓글 평균 길이를 집계하고, 총 댓글 수 내림차순 → 평균 길이 내림차순으로 정렬하여 상위 5명을 출력하세요.  
db.comments.aggregate([
  {$group:{
    _id:"$email",
    commentCount:{$sum:1},
    avgLength:{$avg:{$strLenCP:"$text"}}
  }},
  {$sort:{commentCount:-1,avgLength:-1}},
  {$limit:5}
])

