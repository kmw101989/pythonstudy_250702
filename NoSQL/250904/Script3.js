db.createCollection("reviews")

db.reviews.insertMany(
  [
    {
      customer_name:"김민지",
      product:"여름 원피스",
      rating: 5,
      comment: "옷이 가볍고 시원해서 마음에 들어요",
      date: ISODate("2024-07-15")
    },
    {
      customer_name:"이준",
      product:"여름 원피스",
      rating: 3,
      comment: "디자인은 좋은데 배송이 너무 늦어요",
      date: ISODate("2024-06-20")
    },
    {
      customer_name:"박서연",
      product:"남성 반팔 티셔츠",
      rating: 4,
      comment: "세탁 후에도 형태가 잘 유지돼서 좋아요",
      date: ISODate("2024-08-05")
    },
    {
      customer_name:"이정재",
      product:"스니커즈",
      rating: 2,
      comment: "사이즈가 작게 나와서 교환했습니다",
      date: ISODate("2023-09-10")
    },
    {
      customer_name:"최유리",
      product:"스니커즈",
      rating: 5,
      comment: "가볍고 편해서 매일 신고 있어요",
      date: ISODate("2024-08-18")
    },
    
  ]
)

db.reviews.find()

db.reviews.find(
  {rating: {$gte:4}}
)

db.reviews.find(
  {product:{$eq:"스니커즈"}}
)

db.reviews.updateOne(
  {customer_name:"이준"},
  {$set: {comment:"배송이 빨라서 만족합니다"}}
)
db.reviews.deleteMany(
  {date:{$lt:ISODate("2023-10-01")}}
)

db.reviews.updateMany(
  {product: "여름 원피스"},
  {$inc: {rating:1 }}
)