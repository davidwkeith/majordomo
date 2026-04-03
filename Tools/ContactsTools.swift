import Foundation
import Contacts

/// Contacts.framework access.
struct ContactsTools {
    
    // MARK: - Contact Store
    
    private let contactStore = CNContactStore()
    
    // MARK: - Authorization
    
    /// Check the current authorization status for accessing contacts.
    func checkAuthorizationStatus() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    /// Request authorization to access contacts.
    func requestAuthorization() async throws -> Bool {
        return try await contactStore.requestAccess(for: .contacts)
    }
    
    // MARK: - Search Contacts
    
    /// Search for contacts matching a query string.
    /// - Parameters:
    ///   - query: Search string to match against contact names
    ///   - limit: Maximum number of results to return (default: 20)
    /// - Returns: Array of matching contacts as dictionaries
    func searchContacts(query: String, limit: Int = 20) throws -> [[String: Any]] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor
        ]
        
        let predicate = CNContact.predicateForContacts(matchingName: query)
        let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        
        let limitedContacts = contacts.prefix(limit)
        return limitedContacts.map { contact in
            contactToDictionary(contact)
        }
    }
    
    /// Get all contacts (use with caution for large contact lists).
    /// - Parameter limit: Maximum number of results to return (default: 100)
    /// - Returns: Array of all contacts as dictionaries
    func getAllContacts(limit: Int = 100) throws -> [[String: Any]] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        var contacts: [CNContact] = []
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        fetchRequest.sortOrder = .familyName
        
        try contactStore.enumerateContacts(with: fetchRequest) { contact, stop in
            contacts.append(contact)
            if contacts.count >= limit {
                stop.pointee = true
            }
        }
        
        return contacts.map { contact in
            contactToDictionary(contact)
        }
    }
    
    /// Get a specific contact by identifier.
    /// - Parameter identifier: The unique identifier of the contact
    /// - Returns: Contact information as a dictionary, or nil if not found
    func getContact(byIdentifier identifier: String) throws -> [String: Any]? {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactMiddleNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactDepartmentNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactNoteKey as CNKeyDescriptor
        ]
        
        do {
            let contact = try contactStore.unifiedContact(withIdentifier: identifier, keysToFetch: keysToFetch)
            return contactToDictionary(contact)
        } catch {
            return nil
        }
    }
    
    /// Search contacts by email address.
    /// - Parameter email: Email address to search for
    /// - Returns: Array of matching contacts
    func searchContactsByEmail(_ email: String) throws -> [[String: Any]] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        var matchingContacts: [CNContact] = []
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
            for emailAddress in contact.emailAddresses {
                if emailAddress.value as String == email {
                    matchingContacts.append(contact)
                    break
                }
            }
        }
        
        return matchingContacts.map { contact in
            contactToDictionary(contact)
        }
    }
    
    /// Search contacts by phone number.
    /// - Parameter phoneNumber: Phone number to search for
    /// - Returns: Array of matching contacts
    func searchContactsByPhone(_ phoneNumber: String) throws -> [[String: Any]] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        var matchingContacts: [CNContact] = []
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        try contactStore.enumerateContacts(with: fetchRequest) { contact, _ in
            for phone in contact.phoneNumbers {
                let digits = phone.value.stringValue.filter { $0.isNumber }
                let searchDigits = phoneNumber.filter { $0.isNumber }
                if digits.contains(searchDigits) || searchDigits.contains(digits) {
                    matchingContacts.append(contact)
                    break
                }
            }
        }
        
        return matchingContacts.map { contact in
            contactToDictionary(contact)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert a CNContact to a dictionary representation.
    private func contactToDictionary(_ contact: CNContact) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["identifier"] = contact.identifier
        dict["givenName"] = contact.givenName
        dict["middleName"] = contact.middleName
        dict["familyName"] = contact.familyName
        dict["namePrefix"] = contact.namePrefix
        dict["nameSuffix"] = contact.nameSuffix
        
        if contact.isKeyAvailable(CNContactNicknameKey) {
            dict["nickname"] = contact.nickname
        }
        
        if contact.isKeyAvailable(CNContactOrganizationNameKey) {
            dict["organizationName"] = contact.organizationName
        }
        
        if contact.isKeyAvailable(CNContactDepartmentNameKey) {
            dict["departmentName"] = contact.departmentName
        }
        
        if contact.isKeyAvailable(CNContactJobTitleKey) {
            dict["jobTitle"] = contact.jobTitle
        }
        
        // Email addresses
        if contact.isKeyAvailable(CNContactEmailAddressesKey) {
            dict["emailAddresses"] = contact.emailAddresses.map { labeled in
                [
                    "label": CNLabeledValue<NSString>.localizedString(forLabel: labeled.label ?? ""),
                    "value": labeled.value as String
                ]
            }
        }
        
        // Phone numbers
        if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
            dict["phoneNumbers"] = contact.phoneNumbers.map { labeled in
                [
                    "label": CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: labeled.label ?? ""),
                    "value": labeled.value.stringValue
                ]
            }
        }
        
        // Postal addresses
        if contact.isKeyAvailable(CNContactPostalAddressesKey) {
            dict["postalAddresses"] = contact.postalAddresses.map { labeled in
                let address = labeled.value
                return [
                    "label": CNLabeledValue<CNPostalAddress>.localizedString(forLabel: labeled.label ?? ""),
                    "street": address.street,
                    "city": address.city,
                    "state": address.state,
                    "postalCode": address.postalCode,
                    "country": address.country
                ]
            }
        }
        
        // URL addresses
        if contact.isKeyAvailable(CNContactUrlAddressesKey) {
            dict["urlAddresses"] = contact.urlAddresses.map { labeled in
                [
                    "label": CNLabeledValue<NSString>.localizedString(forLabel: labeled.label ?? ""),
                    "value": labeled.value as String
                ]
            }
        }
        
        // Birthday
        if contact.isKeyAvailable(CNContactBirthdayKey), let birthday = contact.birthday {
            var birthdayDict: [String: Int] = [:]
            if let year = birthday.year {
                birthdayDict["year"] = year
            }
            if let month = birthday.month {
                birthdayDict["month"] = month
            }
            if let day = birthday.day {
                birthdayDict["day"] = day
            }
            dict["birthday"] = birthdayDict
        }
        
        // Notes
        if contact.isKeyAvailable(CNContactNoteKey) {
            dict["note"] = contact.note
        }
        
        return dict
    }
}
