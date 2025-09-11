use sample_mflix
db.movies.find().limit(1)

db.movies.find(
  {year: {$gte: 2010},genres:"Action"},
  {_id:0,title:1,year:1,genres:1}
)

db.movies.aggregate([
  {$match: {year:{$gte:2010},genres:"Action"}},
  {$project: {_id:0,title:1,year:1,genres:1}}
])

db.users.insertOne({
  name:"홍길동",
  email: "hong@test.com",
  password: "test123",
  preference: ["Action","Comedy"],
  createdAt : new Date()
})

db.users.aggregate([
  {$documents: [
    {
    name:"홍길동",
    email: "hong@test.com",
    password: "test123",
    preference: ["Action","Comedy"],
    createdAt : new Date()
    }]}
])

db.comments.find({name:"홍길동"})

//"5a9427648b0beebeb69579cc"

db.comments.insertOne({
  name: "홍길동",
  email:"hong@test.com",
  movie_id:"573a1390f29313caabcd4135",
  text: "Action 영화 최고",
  date: new Date()
})

db.comments.find({name:"홍길동"})

// javascript = 변수를 선언할 때, const, let ,var 
// const => 재선언, 재할당 불가 // 엄격한 변수 
// let => 재선언 불가, 재할당 가능 // 상대적으로 덜 엄격한 변수 
// var => 재선언,재할당 가능 // 가장 자유로운 변수 

const m = db.movies.findOne(
  {year: {$gte: 2010},genres: "Action"},
  {_id:1,title:1}
)

m._id

db.comments.updateOne({
  email:"hong@test.com",movie_id:m._id},
  {$set: {text:"Action 영화 진짜 재밌다!",editedAt:new Date()}}
)

db.movies.aggregate([
  {$unwind:"$genres"},
  {$group: {
    _id:"$genres",count:{$sum:1}
  }},
  {$sort:{count:-1}},
  {$limit:3}
])

db.movies.find(
  { "imdb.rating":{$gte:8.5}},
  {_id:0,title:1,year:1,"imdb.rating":1}
).sort({year:-1})

db.movies.aggregate([
  {$match:{"imdb.rating":{$gte:8.5}}},
  {$project:{_id:0,title:1,year:1,"imdb.rating":1}},
  {$sort:{year:-1}}
])

db.comments.aggregate([
  {
    $addFields:{
      textStr:{
        $convert:{
          input:"$text",
          to:"string",
          onError:"",
          onNull:""
        }
      }
      
    }
  },
  {
    $addFields: {
      textLen:{$strLenCP:"$textStr"}
    }
  },
  {
    $group:{
      _id:"$email",
      totalComments:{$sum:1},
      avgTextLength: {$avg: "$textLen"}
    }
  },
  {$sort: {totalComments: -1 , avgTextLength: -1}},
  {$limit: 5}
])



db.comments.aggregate([
  {
    $addFields: {
      textLen: {
        $strLenCP: {
          $convert: {
            input: "$text",
            to: "string",
            onError: "",
            onNull: ""
          }
        }
      }
    }
  },
  {
    $group: {
      _id: "$email",
      totalComments: { $sum: 1 },
      avgTextLength: { $avg: "$textLen" }
    }
  },
  { $sort: { totalComments: -1, avgTextLength: -1 } },
  { $limit: 5 }
])
