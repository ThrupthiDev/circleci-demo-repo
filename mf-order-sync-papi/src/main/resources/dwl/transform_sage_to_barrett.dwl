%dw 2.0
output application/json


var ship_to_country_code = payload["ADB2_1"]["CRY"]
var accessory_skus =(valuesOf((vars.geoComponent filter ($.country_code == (ship_to_country_code) ))[0]-"country_code"-"country")) ++ ["A1100-FRU","A1100-PCK","A3516-PCK","A3700-PCK","A3950-PCK"]
var sage_order_lines= payload.SOH4_1 filter ((linedata) -> !(["succ", "soft", "serv", "upg"] contains linedata["CCE6"] ) )
var service_map = readUrl("classpath://mapping/service_map.json", "application/json")
var sage_barrett_carrier_map = readUrl("classpath://mapping/sage_barrett_carrier_map.json", "application/json")
var sage_barrett_terms_map = readUrl("classpath://mapping/sage_barrett_terms_map.json", "application/json")
var sage_barrett_service_types_map = readUrl("classpath://mapping/sage_barrett_service_types_map.json", "application/json")

fun format_sage_order_line_to_barrett(line) =
{
        "itemId": line["ITMREF"],
        "orderedQuantity": (line["QTY"]) as Number,
        "orderedQuantityUom": "EA",
        "upc": "",
        "Description": line["ITMDES"],
        "custom": {
            "customNumbers": [
                {
                    
                    "name": "DTLPASSTHRUNUM01",
                    "value": (line["QTY"]) as Number * ((line["DISCRGVAL2"] default 0) as Number + (line["DISCRGVAL3"] default 0) as Number),
                },
                { 
                    "name": "DTLPASSTHRUDOLL02",
                    "value": (line["QTY"]) as Number * (((line["NETPRI"] default 0) as Number - (line["DISCRGVAL2"] default 0) as Number + (line["DISCRGVAL3"] default 0) as Number))
                },
                {
                    
                    "name": "DTLPASSTHRUDOLL01",
                    "value": (line["NETPRI"] default 0) as Number,
                }
            ],
            "customStrings": [
                {
                   
                    "name": "DTLPASSTHRUCHAR06",
                    "value": if ((accessory_skus contains line.ITMREF) and ((line.GROPRI as Number == 0))) "Y" else "N",
                },
                {
                    
                    "name": "DTLPASSTHRUCHAR10",
                    "value": line["SOPLIN"],
                }
            ]
        }
    }

fun sage_carrier_to_barrett(sage_carrier: String, service_level= null) =
if ( service_level == "14" ) "CPU"
 else sage_barrett_carrier_map[sage_carrier]
 
fun sage_terms_to_barrett(sage_terms: String, sage_service_level=null)=
if ( sage_service_level == "6" ) "DT3"
else sage_barrett_terms_map[sage_terms]

fun sage_shipment_service_types_to_barrett( sage_service_type: String, sage_delivery_terms=null)=
 if ( sage_service_type == "22" and sage_delivery_terms == "DDP" ) "L"
         else sage_barrett_service_types_map[sage_service_type]
         
fun sage_service_to_barrett(ship_to_country,sage_carrier,sage_shipping_service) =
if ((isEmpty(service_map[sage_carrier])))
null
 else if (!( service_map[sage_carrier][ship_to_country]?))
   if ( typeOf(service_map[sage_carrier]["International"])!= String)
    if ((!( service_map[sage_carrier]["International"][sage_shipping_service]?)))
 service_map[sage_carrier]["International"]["default"]
 else
 service_map[sage_carrier]["International"][sage_shipping_service]
 else
 service_map[sage_carrier]["International"]
     
 else if (typeOf(service_map[sage_carrier][ship_to_country] )!= String)
 if ((!( service_map[sage_carrier][ship_to_country][sage_shipping_service]?)))
 service_map[sage_carrier][ship_to_country]["default"]
 else
 service_map[sage_carrier][ship_to_country][sage_shipping_service]
 else
 service_map[sage_carrier][ship_to_country]
        

     
   

---
{
	dates: {
		shipDateStart: payload.SOH2_2.DEMDLVDAT as Date {
			"format": "yyyyMMdd"
		} as String {
			"format": "yyyy-MM-dd"
		}
	},
	
	"items": sage_order_lines map ((item, index) -> 
format_sage_order_line_to_barrett(item) ),
	billTo: {
		city: payload.ADB3_1.CTY,
		email: payload.SOH1_1.YEMAIL,
		phone: payload.SOH1_1.YORDPHONE,
		state: if ( payload.ADB3_1.SAT? ) payload.ADB3_1.SAT else "NA",
		country: payload.ADB3_1.CRY,
		streetOne: payload.ADB3_1.BPAADDLIG[0],
		streetTwo: payload.ADB3_1.BPAADDLIG[1] ++ " " ++ payload.ADB3_1.BPAADDLIG[2],
		postalCode: payload.ADB3_1.POSCOD,
		companyName: payload.ADB3_1.BPRNAM[0],
		contactName: if ( payload.ADB3_1.BPRNAM[1]? ) payload.ADB3_1.BPRNAM[1] else payload.ADB3_1.BPRNAM[0]
	},
	custom: {
		customNumbers: [{
			name: "HDRPASSTHRUNUM04",
			value: payload.SOH3_5[0].INVDTAAMT
		}],
		customStrings: [{
			name: "HDRPASSTHRUCHAR16",
			value: "46-2950610"
		},
		{
			name: "HDRPASSTHRUCHAR18",
			value: "N"
		},
		{
			"name": "HDRPASSTHRUCHAR19",
			"value": (payload.SOH1_7.YEECNUM replace " " with "") replace "-" with "",
		},
                {
			"name": "HDRPASSTHRUCHAR20",
			"value": payload.SOH1_6.YEORI
		},
                {
			"name": "HDRPASSTHRUCHAR15",
			"value": payload.SOH0_1.YAPON,
		},
                {
			"name": "HDRPASSTHRUCHAR40",
			"value": payload["SOH2_1"]["YPSAN"],
		},
                {
			"name": "HDRPASSTHRUCHAR49",
			"value": payload["SOH2_3"]["EECICT"],
		},
                {
			"name": "HDRPASSTHRUCHAR21",
			"value": payload["SOH1_7"]["YORDADMNTE"],
		},
                {
			"name": "HDRPASSTHRUCHAR22",
			"value": payload["SOH2_3"]["ICTCTY"],
		},
                {
			"name": "HDRPASSTHRUCHAR24",
			"value": payload.YSLG_3.YIMPORTER,
		},
                {
			"name": "HDRPASSTHRUCHAR03",
			"value": payload.YSLG_2.YCUSTIMPORT,
		},
                {
			"name": "HDRPASSTHRUCHAR04",
			"value": payload.YSLG_2.YIMPTEL,
		},
                {
			"name": "HDRPASSTHRUCHAR05",
			"value": payload.YSLG_2.YIMPTCONTACT,
		},]
	},
	shipTo: {
		city: payload.ADB2_1.CTY,
		state: if ( payload.ADB2_1.SAT? ) payload.ADB2_1.SAT else "NA",
		country: payload.ADB2_1.CRY,
		streetOne: payload.ADB2_1.BPAADDLIG[0],
		streetTwo: payload.ADB2_1.BPAADDLIG[1] ++ " " ++ payload.ADB2_1.BPAADDLIG[2],
		postalCode: payload.ADB2_1.POSCOD,
		companyName: payload.ADB2_1.BPRNAM[0],
		contactName: if ( payload.ADB2_1.BPRNAM[1]? ) payload.ADB2_1.BPRNAM[1]  else payload.ADB2_1.BPRNAM[0]
	},
	orderId: payload.SOH0_1.SOHNUM,
	orderType: "outgoing",
	customerId: "1805",
	orderStatus: "NEW",
	fromFacility: "BRI",
	purchaseOrder: payload.SOH0_1.YCPON,
	"transport": {
		"carrier": sage_carrier_to_barrett(
               payload["SOH2_3"]["BPTNUM"],  
                payload["SOH2_3"]["MDL"]
            ),
		service: sage_service_to_barrett(
                payload["ADB2_1"]["CRYNAM"],  
                payload["SOH2_3"]["BPTNUM"], 
                payload["SOH2_3"]["MDL"]
            ),
		"terms": sage_terms_to_barrett(
                payload["SOH2_3"]["EECICT"],  
                payload["SOH2_3"]["MDL"]
            ),
		"type": sage_shipment_service_types_to_barrett(
                payload["SOH2_3"]["MDL"],  
                payload["SOH2_3"]["EECICT"]),
                
	}
}


