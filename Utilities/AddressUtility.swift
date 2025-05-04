import Foundation
import CoreLocation
import Contacts

class AddressUtility {
    
    // Format a string address to a formatted address
    static func formatAddress(_ address: Address) -> String {
        var components: [String] = []
        if !address.street.isEmpty { components.append(address.street) }
        if !address.city.isEmpty { components.append(address.city) }
        if !address.state.isEmpty { components.append(address.state) }
        if !address.postalCode.isEmpty { components.append(address.postalCode) }
        if !address.country.isEmpty { components.append(address.country) }
        
        return components.joined(separator: ", ")
    }
    
    // Convert a postal address to our Address struct
    static func convertFromPostalAddress(_ postalAddress: CNPostalAddress) -> Address {
        var address = Address()
        address.street = postalAddress.street
        address.city = postalAddress.city
        address.state = postalAddress.state
        address.postalCode = postalAddress.postalCode
        address.country = postalAddress.country
        return address
    }
    
    // Convert our Address struct to a CNPostalAddress
    static func convertToPostalAddress(_ address: Address) -> CNMutablePostalAddress {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = address.street
        postalAddress.city = address.city
        postalAddress.state = address.state
        postalAddress.postalCode = address.postalCode
        postalAddress.country = address.country
        return postalAddress
    }
    
    // Geocode an address to get coordinates
    static func geocodeAddress(_ address: Address, completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        let addressString = formatAddress(address)
        
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil, NSError(domain: "AddressUtility", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get coordinates for address"]))
                return
            }
            
            completion(location.coordinate, nil)
        }
    }
    
    // Given coordinates, reverse geocode to get an address
    static func reverseGeocodeLocation(latitude: Double, longitude: Double, completion: @escaping (Address?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let postalAddress = placemark.postalAddress else {
                completion(nil, NSError(domain: "AddressUtility", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not get address for coordinates"]))
                return
            }
            
            let address = convertFromPostalAddress(postalAddress)
            completion(address, nil)
        }
    }
} 