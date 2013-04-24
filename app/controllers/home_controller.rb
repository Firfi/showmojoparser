require 'open-uri'
require 'json'
require 'uri'
require 'net/http'
require 'rest_client'

class HomeController < ApplicationController
  def index
    raw_xml = open('http://feed.postlets.com/wunderrent/4afce2be4072d42')
    raw_hash = Hash.from_xml(raw_xml)['postlets']['listing']
    sanitized_hash = {:listings => []}
    code = 0
    raw_hash.each do |details|
      new_listing = {
          :code => "cd-#{code += 1}",
          :address => details['location']['street'][0..100],
          :city => details['location']['city'][0..30],
          :state => details['location']['state'],
          :title => details['title'],
          :square_feet => details['details']['sqft'],
          :highlights => details['details']['property_features'],
          :images => details['photos'].reject{|k, v| k.starts_with? 'photo_caption'}.map{|k, v| v}

      }
      bedrooms = details['details']['bedrooms']
      new_listing['bedrooms'] = bedrooms if bedrooms
      full_bathrooms = details['details']['full_bathrooms']
      new_listing['full_bathrooms'] = full_bathrooms if full_bathrooms
      partial_bathrooms = details['details']['partial_bathrooms']
      new_listing['partial_bathrooms'] = partial_bathrooms if partial_bathrooms
      pets = details['details']['pets'].split(', ').reject{|pet| pet == 'No pets'}.map{|pet| pet + ' ok'}
      puts pets
      new_listing['pets'] = pets unless pets.empty? # can't be empty array in api
      new_listing['rent'] = details['details']['money']['price'] if details['details']['property_for'] == 'Rent'
      sanitized_hash[:listings] << new_listing
    end
    @json = sanitized_hash.to_json
    @pretty = JSON.pretty_generate(sanitized_hash)



    @resp = HomeController.post "https://showmojo.com/api/v1/listings", @json, {
        :content_type => 'application/json',
        :accept => 'application/json',
        :authorization => 'Token token="109b38d4a46467647de54294a570a3b3"'
    } do |response, request, result, &block|
        response
    end
    #'Authorization:	Token	token="109b38d4a46467647de54294a570a3b3"'	\
  end

  def self.post(url, payload, headers={}, &block)
    RestClient::Request.execute(:method => :post, :url => url, :timeout => 90000000, :payload => payload, :headers => headers,  &block)
  end

end
