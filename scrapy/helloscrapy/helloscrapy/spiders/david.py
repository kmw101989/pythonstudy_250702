import scrapy


class DavidSpider(scrapy.Spider):
    name = "david"
    allowed_domains = ["davelee-fun.github.io"]
    start_urls = ["https://davelee-fun.github.io"]

    def parse(self, response):
    
        pass