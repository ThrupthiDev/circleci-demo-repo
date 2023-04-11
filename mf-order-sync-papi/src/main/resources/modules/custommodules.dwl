%dw 2.0

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