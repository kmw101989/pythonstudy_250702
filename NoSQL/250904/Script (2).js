use sample_mflix
db.movies.find() 
db.movies.aggregate(
  [
    {$match: {year:1995}}
  ]
)

db.comments.aggregate([
  {
    $group:{
      _id: "$movie_id",
      commentCount:{$sum:1}
    }
  },
  {
    $project: {
      year: "$_id",
      commentCount:1,
      _id:0
    }
  }
])


db.movies.aggregate([
  {
    $group: {
      _id:"$year",
      runtime: {$avg: "$runtime"}
    }
  }
])
db.movies.find().limit(2)

db.movies.aggregate([
  {
    $group: {
      _id:"$year",
//      averageRating:{$avg:"$imdb.rating"}
        minRating: {$min: "$imdb.rating"},
        maxRating: {$max: "$imdb.rating"}
    } 
  }
])

db.movies.aggregate([
  {
    $group : {
       _id: "$year",
       titles:{$push: "$title"}
    }
  }
])

db.movies.aggregate([
  {
    $addFields: {
      ratingNum: {
        $convert: {
          input: "$imdb.rating",
          to: "double", // 실수자료형으로 자료의 값을 변경 
          onError: null, // "", " abc" -> null
          onNull: null // 진짜 null -> null
        }
      }
    }
  },
  {
    $match: {ratingNum: {$ne: null}}
  },
  {
    $group: {
      _id: "$year",
      minRating: {$min: "$ratingNum"},
      maxRating: {$max: "$ratingNum"}
    }
  }
])


db.movies.aggregate([
  {
    $group:{
      _id: "$year",
      genres:{$push: "$directors"}
    }
  }
])
// $addToSet: 동일한 중복값을 제거하고 하나로 가져오는 역할 
db.movies.aggregate([
  {
    $group:{
      _id: "$year",
      genres:{$addToSet: "$directors"}
    }
  }
])

db.movies.find(

)

db.movies.aggregate([
  {
      $group:{
        _id:"$year",
        genres:{$addToSet:"$genres"}
      }
  }
])


db.movies.aggregate([
  {
    $group:{
      _id: "$year",
      firstMovie:{$first:"$title"},
      lastMovie: {$last:"$title"}
      }
  }
])



db.movies.aggregate([
  {
    $group:{
      _id: "$year",
      avgTitleLength : {$avg:{$strLenCP :{$toString:"$title"}}}
      }
  }
]) 

db.movies.aggregate([
  {$match: {year:{$gte:2000}}},
  {$count: "movies_since_2000"}
])

db.movies.find().limit(5)
db.movies.aggregate([
  { $sort: { year: 1, title: 1 } }, 
  { $limit: 10 }
])



db.movies.aggregate([
  {$sort:{"imdb.rating":1}},
  {$limit : 5}
  
])

db.movies.aggregate([
  {$match:{year:{$gte:2000}}},
  {$count: "total_movies"}
  
])

// 2. 각 연ㄴ도별 출시된 영화의 개수 
db.movies.aggregate ([
  {$group: 
    {_id:"$year",count:{$sum:1}}
  },
  {$sort:{_id:1}}
])

// 3. 가장 많은 영화가 ㅏ나온 연도 
db.movies.aggregate ([
  {$group:{
    _id:"$year",
    count: {$sum : 1}
  }},
  {$sort:{count:1}},
  {$limit: 1}
])


// 4. 각 연도별 평균 영화 러닝타임 
db.movies.aggregate ([
 {$group: {
   _id:"$year",
   avgRuntime: {$avg: "$runtime"}
 }}
])

// 가장 러닝타임이 긴 영화는 어떤 영화인가요? 
db.movies.aggregate([
  {$sort: {
    runtime:-1
   }},   
  {$limit: 1}
])

// 각 영화 장르별 평균 평점 
db.movies.aggregate ([
  {$unwind : "$genres"},
  {$group :{
    _id : "$genres",
    avgRating:{$avg: '$imdb.rating'}
  }}
])

// 각 연도별 영화 제목의 평균 길이 
db.movies.aggregate ([
  {$group : {
    _id: "$year",
    avgTitle : {$avg:{$strLenCP :{$toString:"$title"}}}
  }},
  {$sort: {avgTitle: 1}}
])

// 연도별 가장 먼저 출시된 영화의 제목
db.movies.aggregate([
  {$sort:{"year":1}},
  {$group:{_id:"$year",first}},
  {$sort:{_id:1}}
])

// 9. 각 연도별 개봉된 영화의 장르를 출력 . 장르는 한번씩만 출력 '
db.movies.aggregate ([
  {$unwind:"$genres"},
  {$group:{
    _id: "$year",
    uniqueGenres:{$addToSet:"$genres"}}},
    {$sort: {_id:1}}
  
])


db.movies.find()