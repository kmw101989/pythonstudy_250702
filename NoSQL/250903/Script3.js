/*







3) 10개의 raw data는 임의로 생성하시되, 위 문제를 해결할 수 있도록 생성해주세요!!
*/

db.createCollection("reviews")
db.reviews.insertMany(
    [
        {customer_name:"A",product:"p_1",rating:3,comment:"적당해요",date:ISODate("2024-01-01")},
        {customer_name:"B",product:"p_2",rating:5,comment:"좋아요",date:ISODate("2024-02-01")},
        {customer_name:"C",product:"p_3",rating:2,comment:"아쉬워요",date:ISODate("2024-03-01")},
        {customer_name:"D",product:"p_4",rating:4,comment:"좋아요",date:ISODate("2024-04-01")},
        {customer_name:"E",product:"p_1",rating:3,comment:"적당해요",date:ISODate("2024-05-01")},
        {customer_name:"F",product:"p_2",rating:3,comment:"적당해요",date:ISODate("2024-06-01")},
        {customer_name:"G",product:"p_3",rating:5,comment:"좋아요",date:ISODate("2024-07-01")},
        {customer_name:"H",product:"p_4",rating:1,comment:"별로에요",date:ISODate("2024-08-01")},
        {customer_name:"I",product:"p_2",rating:2,comment:"아쉬워요",date:ISODate("2024-09-01")},
        {customer_name:"J",product:"p_3",rating:3,comment:"적당해요",date:ISODate("2024-10-01")}
        
    ]
)
//별점(rating)이 4점 이상인 리뷰만 조회하세요.
db.reviews.find(
  {rating:{$gt:4}}
)
//특정 제품(product)의 리뷰만 필터링하세요.
db.reviews.find(
  {product:{$eq:"p_3"}}
)
//한 고객의 리뷰 코멘트를 "배송이 빨라서 만족합니다"로 수정하세요.
db.reviews.updateOne(
    {customer_name:"A"},
    {$set:{comment:"배송이 빨라서 만족합니다"}}
)
db.reviews.find(
  {customer_name:"A"}
)
//특정 제품의 리뷰 별점을 일괄적으로 +1 해보세요.
db.reviews.updateMany(
  {product:"p_2"},
  {$inc:{rating:1}}
)
db.reviews.find()

//오래된 리뷰(date 기준 1년 이상 지난 것)를 삭제하세요.
db.reviews.deleteMany(
  {date:{$lt:ISODate("2024-06-03")}}
)
db.reviews.find()
