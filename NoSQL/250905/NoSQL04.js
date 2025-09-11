// 각 영화의 제목과 해당 영화에 달린 댓글을 조회해주세요 
db.movies.aggregate([
  {
    $lookup: 
      {
        from:"comments",
        localField:"_id",
        foreignField:"movie_id",
        as:"comment_text"
      }
  },
  {
    $project:{
      _id:0,
       title:1,
       comment_text:{
        $map : {
          input: "$movie_commants",
          as: "comment",
          in:"$$comment.text"  
        }
      }
    }
  }
])


//평점이 가장 높은 영화의 제목과 평점 출력 
db.movies.aggregate([
  {$match:{"imdb.rating":{$ne:""}}},
  {$sort:{"imdb.rating":-1}},
  {$limit:1},
  {$project:{_id:0,title:1,"imdb.rating":1}},
  
])

// 각 장르별로 평균 평점이 가장 높은 장르와 평균 평점을 출력해주세요.
db.movies.aggregate([
  {$unwind:"$genres"},
  {$group:{
    _id:"$genres",
    avgRating:{$avg:"$imdb.rating"}
  }},
  {$sort:{avgRating:-1}},
  {$limit:1},
  {$project:{_id:1,avgRating:1}}
])

// 개봉 연도별 평균 러닝타임이 가장 짧은 영화의 개봉년도와 평균 러닝타임 
db.movies.aggregate([
  {$group:{
    _id:"$year",
    avgRuntime:{$avg:"$runtime"}
  }},
  {$sort:{avgRuntime:1}},
  {$limit:1}
])

db.movies.find()

// 국가별로 가장 많은 영화를 제작한 감독과 그 감독의 영화 수 
db.movies.aggregate([
  {$unwind:"$countries"},{$unwind:"$directors"},
  {$group:{
    _id:{country:"$countries",director:"$directors"},
    directionCount:{$sum:1}
  }},
  {$sort:{directionCount:-1}},
  {$group:{
    _id:"$_id.country",
    topDirectors:{$first:"$_id.director"},
    movieCount:{$first:"$directionCount"},
  }},
  {$sort:{movieCount:-1}}
])

db.movies.aggregate([
  {$unwind:"$countries"},{$unwind:"$directors"},
  {$group:{_id:{country:"$countries",director:"$directors"},
  count: { $sum: 1 }
  }},
  {$group:{
    _id:"$_id.country",
    top:{
      $topN:{
        n:1,
        sortBy:{count:-1},
        output:{director:"$_id.director",movieCount:"$count"}
      }
    }
  }},
  {
    $project:{
      _id:0,
      country:"$_id",
      topDirector:{$first:"$top.director"},
      movieCount:{$first:"$top.movieCount"}
    },
  }
])

// 각 연도별로 가장 많은 평점을 받은 영화의 제목과 평점을 출력하세요 
db.movies.aggregate([
  {$group:{
    _id:"$year",
    sumRating:{$sum:"$imdb.rating"},
    title:{$first:"$sumRating"}
  }},
  {$sort:{"_id":1}}
])

db.movies.aggregate([
  {$sort:{"year":1,"imdb.rating":-1}},
  {$group:{_id:"$year",title:{$first:"$title"},maxRating:{$first:"$imdb.rating"}}},
  {$project:{_id:0,year:"$_id",title:1,maxRating:1}}
])

// 장르별 영화 개수
db.movies.aggregate([
  {$unwind:"$genres"},
  {$group:{
    _id:"$genres",
    count:{$sum:1}
  }},{$sort:{count:-1}},
  {$project:{_id:0,genre:"$_id",movieCount:"$count"}}
])


//평균평점이 가장 높은 감독과 해당 감독의 평균 평점 출력 
db.movies.aggregate([
  {$unwind:"$directors"},
  {$group:{
    _id:"$directors",
    avgRating:{$avg:"$imdb.rating"}
  }},{$sort:{avgRating:-1}},{$limit:1},
  {$project:{_id:0,directors:"$_id",avgRating:1}}
])

//장르별 평균 러닝타임이 가장 긴 장르와 해당 장르의 평균 러닝타임을 출력 
db.movies.aggregate([
  {$unwind:"$genres"},
  {$group:{
    _id:"$genres",
    avgRuntime :{$avg:"$runtime"}
  }},
  {$sort:{avgRuntime:-1}},{$limit:1},
  {$project:{_id:0,avgRuntime:1,genre:"$_id"}}
])

// 각 영화의 제목과 해당 영화에 대해 댓글을 남긴 사용자들을 출력하세요 . 
db.movies.aggregate([
  {
    $lookup: 
      {
        from:"comments",
        localField:"_id",
        foreignField:"movie_id",
        as:"name"
      }
  },
  {$project:{
    _id:0,
    title:1,
    name:"$name.name"
  }}
])

db.comments.find()
