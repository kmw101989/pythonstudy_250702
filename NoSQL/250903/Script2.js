//로컬컴퓨터 내 DB 목록 확
show dbs
//특정db에 접속
use funcoding
use nosql01
show collections
//특정 db안에 컬렉션을 보고자 할 떄
show collections
//특정 컬렉션안에 데이터를 확인하고자 할 때
db.test.find()
//특정 db의 상태정보를 확인할 때
db.stats()
//특정db 삭제 하는 방법
//db가 삭제 된다는 것은 컬렉션도 같이 삭제가 된다는 의미
//컬렉션을 먼저 지우고 db를 삭제하는 순서로 합시다
db.dropDatabase()
use funcoding
//특정 db안에 컬렉션 드랍하기
db.test.drop()
//컬렉션을 cli 방식으로 create
db.createCollection("test")

use funcoding
// 컬렉션을 생성하는 두가지 방식
/*
1)특정 옵션 없이 단순 컬렉션 생성 방식
2)별도의 옵션을 설정해서 컬렉션 생성 방식 
-capped : True => 
-size : byte 의 단위로 입력하게끔 되어있음 
-1byte = 8bit
-1kb = 1024 byte 
- 1mb = 1 x 1024 x 1024 = 
-max : 해당 컬렉션 안에 저장할 수 있는 데이터 = 문서 , 몇 개의 문서를 허용할 것인가 
-autoIndexId : true => 모든 문서를 생성할 때마다 _id 필드에 대한 값을 자동으로 설정할 것인가 

*/
db.createCollection("log",{
    capped : true ,
    size: 5242880, 
    max: 5000, 
})
db.log.isCapped()
db.test.isCapped()

// 이미 생성된 컬렉션 이름을 수정하고자 할 때 
db.log.renameCollection("test01")

/* 
SQL : 
INSERT INTO tablename(field name) VALUES (value);

NoSQL :
db.collectionname.insertOne(
    {
        name: "David",
        age: 20,
        status: "pending"
    }
)



db.collectionname.insertMany(
    [
        {subject: "coffee", author:"abc",views: 50}
        {subject: "shopping", author:"def",views: 100}
        
    ]
)
*/

db.createCollection("users") 
db.users.insertOne(
    {subject:"coding",author:"funcoding",views: 50}
)
// 해당 컬렉션 내부에 있는 값을 확인하고자 할 떄 
db.users.find()
// 해당 컬렉션 내부에 여러개의 문서를 동시에 입력 
db.users.insertMany(
    [
        {subject:"coffee",author : "xyz",views:50},
        {subject:"Coffee Shopping",author : "efg",views:5},
        {subject:"baking a cake",author : "abc",views:90},
        {subject:"baking",author : "xyz",views:100},
        {subject:"Cafe",author : "abc",views:200},
    ]
)
// NoSQL 구문/문법은 SQL 대비 상대적으로 유연한 문법 체계를 가지고 있음 
// {subject : "coffee02", author: "123", views:123} 

// SQL 내 Schema를 정의했던 것처럼 NoSQL에서도 사전에 Schema Validation 유효성 기능설정 
db.createCollection("users2",{
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required:["subject","author","views"],
            properties: {
                subject:{
                    bsonType:"string",
                    description:"must be a string and is required"
                },
                author:{
                    bsonType:"string",
                    description:"must be a string and is required"
                },
                views:{
                    bsonType:"int",
                    description:"must be a integer and is required"
                },
            }
        }
    },
    validationAction: "error"

})

db.users.drop()

// users 컬렉션 생성 
// 다음과 같은 데이터를 삽입 
//컬렉션 내 size는 100000 로 생성 

/*
name,age,hobby,address 키 
David,45,"서울"
Dave, 25 ,"경기도" 
Andy,50,"골프","경기도"
Kate, 35 ,"수원시"
Brown, 8
*/


db.createCollection("users",{
    capped:true,size:100000
})
 db.users.insertMany(
    [
        {name:"David",age:45,address:"서울"},
        {name:"Dave",age:25,address:"경기도"},
        {name:"Andy",age:50,hobby:"골프",address:"경기도"},
        {name:"kate",age:35,address:"수원시"},
        {name:"Brown",age:8},
    ]
)
db.users.find()
db.users.drop()

/* 
만약, 특정 조건에 해당되는 값을 찾아오고 싶다면? 
SELECT * FROM users ;
db.users.find()

SELECT _id, name, address FROM users 
-> 
db.users.find({},{name: 1 , address:1})
> {} : 직접 입력 및 삽입한 값 뿐만 아니라 자동적으로 내장되어 있는 값까지 모두 찾아온다는 의미 = all 
>{특정 값을 입력} : 조건 
SELECT name, address FROM users 
->
db.users.find({},{name;1,address:1, _id:0})

SELECT * FROM users WHERE address = "서울" 
db.users.find({address:"서울"})
*/

// findOne() : 매칭되어지는 한개의 document 문서를 검색해서 찾아온다 
// 어떤 쿼리의 조건을 의미하는 명칭 : query criteria (*기준) 

/* 
db.users.find(
    {age: {$gt: 18}}, -> query criteria 
    {name:1 , address:1}
).limit(5) -> cursor modifier
*/

// users 컬렉션에서 이름이 Dave 인 문서의 name과 age, address ,_id 출력 
db.users.find(
    {name: "Dave"}, 
    {name:1 , age:1,address:1,_id:1}
)

db.users.find(
    {name: "Dave"},
    {name:1,age:1,address:1}
)

db.users.find(
    {name: "kate"},
    {name:1,age:1,address:1}
)


// 비교연사ㅣㄴ자 
/*
$eq : = 
$gt : > 
$gte : >= 
$lt : < 
$lte : <=
$nin
$in : 특정 값을 갖고있다 
$ne : not equal

SELECT * FROM users WHERE age > 25;
db.users.find({age: {$gt: 25}})

SELECT * FROM users WHERE age > 25 AND age <= 50;
db.users.find({age: {$lte:50, $gt: 25}})
*/

db.users.find(
    {age: {$gt:25}}
)

db.users.find(
    {age:{$gt: 25, $lte:50}}
)

db.users.find(
    {age:{$in:[45,50]}}
)
db.users.find(
    {age: {$ne:25}}
)

// 특정조건에 해당되지 않으면 전체데이터 

/*
1) age가 20보다 큰 문서의 name만 출력 
2) age가 50이고, address가 경기도인 문서의 name 만 출력 
3) age가 30보다 작은 문서의 name과 age 출력 

*/

db.users.find(
    {age: {$gt:20}},
    {name:1,_id:0}
)

db.users.find(
    {age:{$eq:50},address:{$eq:"경기도"}},
    {name:1,_id:0}
)

db.users.find(
    {age: {$lt:30}},
    {name:1,age:1,_id:0}
)


// 논리연산 문법 
/* 
SELECT * FROM users WHERE address = "서울" AND age = 45;
db.users.find(
    {$and: [{address: "서울"},{ag: 45}]}
    
SELECT * FROM users WHERE address = "서울" AND age = 45;
db.users.find(
    {$or: [{address: "서울"},{ag: 45}]}
)
*/

db.users.find(
    {$and:[{address:"서울"},{age:45}]}
)

// name이 Brown이거나, age가 35인 모든 값 출력 
db.users.find( 
    {$or : [{name:"Brown"},{age:35}]}
   )
// 정규표현식 -> 어떤 특정 문자열을 찾아오도록 설정 -> 패턴     

/* Name 이 Da 로 시작하는 모든 문서를 찾아라 
db.users.find(
    {name: {$regex:/Da/}}
)
db.users.find(
    {name:/Da/}
)
*/

db.users.find(
    {name:/Da/}
)

/*
db.users.find(
    {address:"경기도"}
).sort({age: -1})
*/

db.users.find(
    {address:"경기도"}
).sort({age:-1})

//현재 컬렉션 내 문서의 개수 확인하고자 할 때 :count()
db.users.find().count()
db.users.count()

// 컬렉션 내 필드 존재 여부로 문서 개수 확인 :$exists : 속성  

db.users.count(
    {address:{$exists:true}}
)

db.users.find({address:{$exists:true}}).count()

db.users.find({address:{$exists:false}}).count()

//중복제거 : distinct 
/*
SELECT DISTINCT(address) FROM users;
db.users.distinct("address")

결과값이 같은 비슷한 구문 : 
db.users.findOne()
db.users.find().limit()
*/ 

db.users.distinct("address")
db.users.find().limit(2) 

// 데이터 수정 => 
// 이미 생성된 컬렉션 안에 신규 값을 추가 

db.users.insertMany(
    [
        {name:"유진", age:25,hobbies:["독서","영화","요리"]},
        {name:"도현", age:30,hobbies:["축구","음악","영화"]},
        {name:"혜진", age:35,hobbies:["요리","여행","독서"]}
    ])
 
 db.users.find()
 
 
db.users.find(
    {hobbies: {$all:["축구","음악"]}}
)
//select * FROM users WHERE hobbies LIKE "%축구%" AND "%음악%"


// Document 수정 
/*
1) updateOne(*정석) // update 
- 매칭되는 1개의 문서를 업데이트할 때 사용 

2) updateMany
- 매칭되는 모든 문서를 업데이트 할 때 사용 

db.users.updateMany(
    {age: {$gr : 25}},
    {$set: {address: "서울"}}
)

UPDATE users SET address = "서울" WHERE age > 25 ; 

*/
// age 가 40보다 큰 문서의 address 를 "수원시로 변경하기 
db.users.updateMany(
    {age: {$gt:40}},
    {$set : {address:"수원시"}}
)
db.users.find()

db.users.updateOne(
    {name:"유진"},
    {$set:{age:26}}
)

// 특정 조건에 부합하는 경우 , 통으로 문서를 대체(replace)  하는 구문 