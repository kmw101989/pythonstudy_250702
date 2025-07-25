import scrapy
from selenium import webdriver
from selenium.webdriver.common.by import by 
import time


class SeleniumTestSpider(scrapy.Spider):
    name = "selenium_test"
    allowed_domains = ["divjason.github.io"]
    start_urls = ["https://divjason.github.io/sellenium-test/"]


    def __init__(self):
       headlessoptions = webdriver.ChromeOptions() 
       headlessoptions.add_argument("headless")
       self.driver = webdriver.Chrome(options=headlessoptions)
    
    def parse(self, response):
        self.driver.get(response.url)
        time.sleep(2) 

        
