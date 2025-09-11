db.comments.aggregate([
  {
     $lookup:
       {
         from:"movies",
         localField: "movie_id",
         foreignField:"_id",
         as:"movie "
       }
  }
])

db.users.find().limit(1)
db.comments.find().limit(1)

db.users.aggregate([
  {
    $lookup: 
      {
        from:"comments",
        localField:"email",
        foreignField:"email",
        as:"user_comments"
      }
  }
])

// lookup : 서로 다른 컬렉션을 연결한다는 장점이 존재 
// 프로그램이 실행되는 측면에서 보면 그렇게 환영받을 만한 코드 x 
// 컬렉션 + 컬렉션 => 새로운 필드 가져오기 로드 2회, 쓰기 1회
// 로컬 컴퓨터의 사양이 좋지 못하거나 클라우드 컴퓨팅 서버의 용량, 자원이 불충분한 경우 -> 무한 로딩의 가능성 

db.movies.aggregate([
  {$match:{runtime:{$gte:100}}},
  {$sort: {year: -1}},
  {$skip: 5 },
  {$limit:3 }
])

db.movies.aggregate([
  {
    $facet: {
      movieCountByYear: [
      {$group:{_id:"$year",count:{$sum:1}}}
      ],
      maxRatingByYear:[
        {$group:{_id:"$year",maxRating:{$max:"$imdb.rating"}}}
      ]
    }
  }
])

db.movies.aggregate([
  {
    $redact : {
      $cond:{
        if: {$gte :["$imdb.rating",7]},// 조건식
        then: "$$KEEP" ,// 조건식이 참 
        else: "$$PRUNE"// 조건식이 거짓
      }
    }
  }
])

db.movies.aggregate([])