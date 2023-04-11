%dw 2.0
import first from dw::core::Strings
output application/json

var sage_vat_id = ((payload["SOH1_7"]["YEECNUM"] as String replace " " with "") replace "-" with "")
var sage_to_tigers_delivery_service = readUrl("classpath://mapping/sage_tigers_delivery_service.json", "application/json")

var ship_to_country_code = payload["ADB2_1"]["CRY"]
var accessory_skus = (valuesOf((vars.geoComponent filter ($.country_code == (ship_to_country_code) ))[0]-"country_code"-"country")) ++ ["A1100-FRU","A1100-PCK","A3516-PCK","A3700-PCK","A3950-PCK"]
var sage_order_lines= payload.SOH4_1 filter ((linedata) -> !(["succ", "soft", "serv", "upg"] contains lower(linedata["CCE6"]) ) )

fun format_tigers_address_line(tigers_address_line) =
tigers_address_line first 40

fun format_sage_order_line_to_tigers(line) = do{
var sku = line["ITMREF"]
var quantity = line["QTY"] as Number
var price_per_unit =  line["NETPRI"] as Number
var promotional_discount_per_unit = if(line["DISCRGVAL2"] != null) line["DISCRGVAL2"] as Number else 0
var discretional_discount_per_unit = if(line["DISCRGVAL3"] != null) line["DISCRGVAL3"] as Number else 0
var discount_per_unit = promotional_discount_per_unit + discretional_discount_per_unit
var hide_on_forms = ((accessory_skus contains sku) and ((line["GROPRI"] as Number == 0)))
	---
	{
		"skuCode": sku,
        "quantity": quantity,
        "unitPrice": price_per_unit,
        "lineCost": quantity * (price_per_unit - discount_per_unit),
        "discountAmount": quantity * discount_per_unit,
        "orderLineNumber": line["SOPLIN"],
        "extendedInfo": if(hide_on_forms) "N" else "Y" 
	}
}

---
{
	salesOrderRef: payload["SOH0_1"]["SOHNUM"],
	consigneeRef: payload["SOH0_1"]["YAPON"] first 20,
	status: "NEW",
	orderDate: payload["SOH0_1"]["ORDDAT"] as Date {
			"format": "yyyyMMdd"
		} as String {
			"format": "yyyy/MM/dd"
	},
	currency: payload["SOH0_1"]["CUR"],
	taxRegistrationNumber: upper(((payload["SOH1_7"]["YEECNUM"] as String replace " " with "") replace "-" with "")),
	deliveryCharge: payload["SOH3_5"][0]["INVDTAAMT"],
	shipDate: payload["SOH2_2"]["DEMDLVDAT"] as Date {
			"format": "yyyyMMdd"
		} as String {
			"format": "yyyy/MM/dd"
	},
	specialInstructions: payload["SOH1_7"]["YORDADMNTE"],
	categoryCode: "B2B",
	deliveryCompany: payload["SOH2_3"]["BPTNUM"],
	deliveryService: sage_to_tigers_delivery_service[payload["SOH2_3"]["MDL"]],
	deliveryTerms: payload["SOH2_3"]["EECICT"],
	paymentTerms: payload["SOH3_3"]["PTE"],
	isResidential: if (payload["SOH2_2"]["DEMDLVDAT"] == "Residential") 1  else 0,
	collectAccountNumber: payload["SOH2_1"]["YPSAN"],
	addresses:[
		{
			addressType: "ST",
			contactName: if(payload["SOH2_2"]["DEMDLVDAT"][1] != null) payload["SOH2_2"]["DEMDLVDAT"][1] else payload["ADB2_1"]["BPRNAM"][0],
			companyName: payload["ADB2_1"]["BPRNAM"][0],
			addressLine1: format_tigers_address_line(payload["ADB2_1"]["BPAADDLIG"][0] default ""),
			addressLine2: format_tigers_address_line(payload["ADB2_1"]["BPAADDLIG"][1] default ""),
			addressLine3: format_tigers_address_line(payload["ADB2_1"]["BPAADDLIG"][2] default ""),
			city: payload["ADB2_1"]["CTY"],
			state: payload["ADB2_1"]["SAT"],
			postcode: payload["ADB2_1"]["POSCOD"],
			countryCode: payload["ADB2_1"]["CRY"],
			phoneNumber: "None",
			faxNumber: payload["SOH1_6"]["YEORI"],
			emailAddress: payload["SOH1_1"]["YEMAIL"]
		},
		{
			addressType: "BY",
			contactName: if(payload["ADB3_1"]["BPRNAM"][1] != null) payload["ADB3_1"]["BPRNAM"][1] else payload["ADB3_1"]["BPRNAM"][0],
			companyName: payload["ADB3_1"]["BPRNAM"][0],
			addressLine1: format_tigers_address_line(payload["ADB3_1"]["BPAADDLIG"][0] default ""),
			addressLine2: format_tigers_address_line(payload["ADB3_1"]["BPAADDLIG"][1] default ""),
			addressLine3: format_tigers_address_line(payload["ADB3_1"]["BPAADDLIG"][2] default ""),
			city: payload["ADB3_1"]["CTY"],
			state: payload["ADB3_1"]["SAT"],
			postcode: payload["ADB3_1"]["POSCOD"],
			countryCode: payload["ADB3_1"]["CRY"],
			phoneNumber: payload["SOH1_1"]["YORDPHONE"],
			emailAddress: payload["SOH1_1"]["YEMAIL"]			
		}
		
	],
	orderLines: sage_order_lines map ((item, index) -> format_sage_order_line_to_tigers(item) )
	
}

