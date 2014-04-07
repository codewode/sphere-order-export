_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
Config = require '../config'
fs = require 'fs'
ChannelService = require '../lib/channelservice'

jasmine.getEnv().defaultTimeoutInterval = 10000

describe 'channelservice tests', ->

  CHANNEL_KEY = 'OrderXmlFileExport'
  CHANNEL_ROLE = 'OrderExport'

  beforeEach (done) ->
    @sphere = new SphereClient Config
    @mapping = new Mapping Config
    @channelService = new ChannelService Config

    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      @channel = result.body
      # get a tax category required for setting up shippingInfo
      #   (simply returning first found)
      @sphere.taxCategories.save(taxCategoryMock())
    .then (result) =>
      @taxCategory = result.body
      @sphere.zones.save(zoneMock())
    .then (result) =>
      zone = result.body
      @sphere.shippingMethods.save(shippingMethodMock(zone, @taxCategory))
    .then (result) =>
      @shippingMethod = result.body
      @sphere.productTypes.save(productTypeMock())
    .then (result) =>
      productType = result.body
      @sphere.products.save(productMock(productType))
    .then (result) =>
      @product = result.body
      @sphere.orders.import(orderMock(@shippingMethod, @product, @taxCategory))
    .then (result) =>
      @order = result.body
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

  afterEach (done) ->
    done()

  it 'should create a new channel and return it', (done) ->
    key = "channel-#{new Date().getTime()}"
    @channelService.byKeyOrCreate(key, CHANNEL_ROLE)
    .then (result) ->
      expect(result.body).toBeDefined()
      expect(result.body.key).toEqual key
      expect(result.body.roles).toEqual [CHANNEL_ROLE]
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

  it 'should fetch an existing channel and return it', (done) ->
    @channelService.byKeyOrCreate(CHANNEL_KEY, CHANNEL_ROLE)
    .then (result) =>
      expect(result.body).toBeDefined()
      expect(result.body.id).toEqual @channel.id
      expect(result.body.roles).toEqual @channel.roles
      done()
    .fail (err) ->
      done(JSON.stringify err, null, 4)

###
helper methods
###

shippingMethodMock = (zone, taxCategory) ->
  unique = new Date().getTime()
  shippingMethod =
    name: "S-#{unique}"
    zoneRates: [{
      zone:
        typeId: 'zone'
        id: zone.id
      shippingRates: [{
        price:
          currencyCode: 'EUR'
          centAmount: 99
        }]
      }]
    isDefault: false
    taxCategory:
      typeId: 'tax-category'
      id: taxCategory.id


zoneMock = ->
  unique = new Date().getTime()
  zone =
    name: "Z-#{unique}"

taxCategoryMock = ->
  unique = new Date().getTime()
  taxCategory =
    name: "TC-#{unique}"
    rates: [{
        name: "5%",
        amount: 0.05,
        includedInPrice: false,
        country: "DE",
        id: "jvzkDxzl"
      }]

productTypeMock = ->
  unique = new Date().getTime()
  productType =
    name: "PT-#{unique}"
    description: 'bla'

productMock = (productType) ->
  unique = new Date().getTime()
  product =
    productType:
      typeId: 'product-type'
      id: productType.id
    name:
      en: "P-#{unique}"
    slug:
      en: "p-#{unique}"
    masterVariant:
      sku: "sku-#{unique}"

orderMock = (shippingMethod, product, taxCategory) ->
  unique = new Date().getTime()
  order =
    id: "order-#{unique}"
    orderState: 'Open'
    paymentState: 'Pending'
    shipmentState: 'Pending'

    lineItems: [ {
      productId: product.id
      name:
        de: 'foo'
      variant:
        id: 1
      taxRate:
        name: 'myTax'
        amount: 0.10
        includedInPrice: false
        country: 'DE'
      quantity: 1
      price:
        value:
          centAmount: 999
          currencyCode: 'EUR'
    } ]
    totalPrice:
      currencyCode: 'EUR'
      centAmount: 999
    returnInfo: []
    shippingInfo:
      shippingMethodName: 'UPS'
      price:
        currencyCode: 'EUR'
        centAmount: 99
      shippingRate:
        price:
          currencyCode: 'EUR'
          centAmount: 99
      taxRate: _.first taxCategory.rates
      taxCategory:
        typeId: 'tax-category'
        id: taxCategory.id
      shippingMethod:
        typeId: 'shipping-method'
        id: shippingMethod.id
