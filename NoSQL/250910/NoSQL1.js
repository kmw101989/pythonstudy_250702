use sample_mflix
//1.users 문서에 commentsCount 필드를 추가하고 댓글 개수계산
// 2. 댓글 길이를 기준으로 100자 이상 => LONG COMMENT 
// array =배열 = list 
//iterable = 반복순회 가능한 자료구조 
// for in => .js => 반복순회 가능한 자료구조를 찾아와서 내부에 있는 값을 하나씩 빼서 연산처리 후 다시 새로운 배열로 반환 
// map 
db.users.find()
db.comments.find()

db.users.aggregate([
  {
   $lookup :{
     from : "comments",
     localField: "name",
     foreignField: "name",
     as: "c"
   }
  },
  {
    $addFields :{
      commentsCount: {$size: "$c"},
      commentsAnntated: {
        $map: {
          input: "$c",
          as: "x",
          in : {
            text: "$$x.text",
            date: "$$x.date",
            movie_id:"$$x.movie_id",
            commentType: {
              $cond:[
              {$gte: [{$strLenCP:{$ifNull:["$$x.text",""]}}, 100]},
              "LONG COMMENT",
              "SHORT COMMENT"
              ]
            }
          }
        }
      }
    }
  }
])


db.movies.aggregate([
  {
    $facet: {
      latest5:[
        {$sort: {year: -1}},
        {$limit: 5}, 
        {$project: {_id:0, title:1, year:1}}
      ],
      highRatedCount: [
        {$match: {"imdb.rating":{$gte:8}}},
        {$count:"count"}
      ],
      genresByCount:[
        {$unwind:"$genres"},
        {$group : {_id:"$genres",count: {$sum:1}}},
        {$sort:{count:-1}}
      ]
    }
  },
  {
    $project:{
      latest5:1,
      highRatedCount: {$ifNull: [{$arrayElemAt:["$highRatedCount.count",0]},0]},
      genresByCount:1
      
    }
  }
])

db.users.find()