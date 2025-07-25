import scrapy
from kmwfun_project2.items import KmwfunProject2Item

class SpiderSpider(scrapy.Spider):
    name = "spider"
    allowed_domains = ["davelee-fun.github.io"]
    start_urls = ["https://davelee-fun.github.io"]

    def parse(self, response):
        item = KmwfunProject2Item()
        item["title"] = response.css("h1.sitetitle::text").get()
        item["description"] = des
        des = response.xpath("//p[@class ='lead']/text()").get()
        
    
    
        yield item 
