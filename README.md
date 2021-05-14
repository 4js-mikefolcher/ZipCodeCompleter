# ZipCodeCompleter
Example of using the Genero completer and zoom

## Getting Started
**Download & Build**
- Download this Git repository to your local machine
- Compile and run that AddressApp application using the GBC

## Using the Zip Code Zoom and Completer
The following code can be used to implement the zip code zoom and completer\
in your application

**Genero Implementation**
```genero

#Call to load the zip code data into memory
CALL buildZipCodeCache()

#Display the zoom window
ON ACTION zoom
        IF INFIELD(zip_code) THEN
                CALL showZipCodeZoom() RETURNING search_zipcode.*
	        IF NOT search_zipcode.isEmpty() THEN
	                LET r_address.zip_code = search_zipcode.zip_code
			LET r_address.city = search_zipcode.city
			LET r_address.state = search_zipcode.state_name
		END IF
	END IF

#Display the Completer list
ON CHANGE zip_code
        CALL zipCodeCompleter(DIALOG, r_address.zip_code)
        IF LENGTH(r_address.zip_code CLIPPED) == 5 THEN
                CALL getZipCodeRec(r_address.zip_code)
                        RETURNING search_zipcode.*
	        LET r_address.city = search_zipcode.city
	        LET r_address.state = search_zipcode.state_name
	END IF

```

### Zip Code Data 
The zip code data is supplied to this application using a CSV file from the\
Free US Zip Code Database website.  See the link below for more details.\
https://simplemaps.com/data/us-zips

