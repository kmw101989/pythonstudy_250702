db.users.find()

db.users.updateOne(
  {name:"도현"},
  {$set:{name:"동현2",age: 31 ,hobbies : ["축구","음악","영화"]}}
)

db.users.find(
  {name:"동현2"}
)

//특정 조건에 따라서 필드를 제거하는 문법/구문 
db.users.updateOne(
  {name:"유진"},
  {$unset:{age:1}}
)

//특정 조건을 만족하는 문서가 없느 경우 , 새로 추가하기 
db.users.updateOne(
  {name:"민준"},
  {$set:{name:"민준",age:22,hobbies:["음악","여행"]}},
  {upsert: true}
)

db.users.updateOne(
  {name:"유진"},
  {$set: {age:30}}
)

db.users.updateOne(
  {name:"유진"},
  {$set: {hobbies:["영화","운동"]}}
)

db.users.updateOne(
  {name:"유진"},
  {$push: {hobbies:"독서"}}
)
db.users.find()


// 특정 컬럼 내 배열 형태의 자료에서 값을 제거 : pull 
db.users.updateOne(
  {name:"유진"},
  {$pull: {hobbies:"운동"}}
)

/*
특정 컬렉션 안에 값을 추가할 때애도 단일값&다중값 적용 
값을 수정할 때에도 단일값 & 다중값 적용 
값을 삭제할 때에도 단일값 & 다중값 적용 

*/
/*
DELETE  FROM users WHERE address = "서울" ;
db.users.deleteMany(
  {address:"서울"}
)

db.users.deleteMany(
  {}
)
DELETE FROM users;
*/

db.users.deleteMany(
  {address: "수원시"}
)
db.users.find()

db.users.insertMany(
  [
    {name:"David",age:45,address:"서울"},
    {name:"DaveLee",age:25,address:"경기도"},
    {name:"Andy",age:50,hobbyies:"골프",address:"경기도"},
    {name:"Kate",age:35,address:"수원시"}
  ]
)

db.users.insertMany(
  [
    {name: "A",address:"경기도",date: ISODate("2025-08-15")},
    {name: "B",address:"서울",date: ISODate("2025-06-15")},
  ]

) 
db.users.find()

db.users.updateMany(
  {address:"경기도"},
  {$inc:{age:1}}
)
db.users.deleteMany(
  {date:{$lt:ISODate("2025-09-01")}}
)
