import Foundation
import CoreData

extension ContactEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContactEntity> {
        return NSFetchRequest<ContactEntity>(entityName: "ContactEntity")
    }

    @NSManaged public var address: String?
    @NSManaged public var birthdate: Date?
    @NSManaged public var birthdateIsAgeBased: Bool
    @NSManaged public var birthdateAge: Int32
    @NSManaged public var isBirthdateKnown: Bool
    @NSManaged public var company: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var detailsSyncedAt: Date?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var id: Int32
    @NSManaged public var jobTitle: String?
    @NSManaged public var lastName: String?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var needsDetailSync: Bool
    @NSManaged public var nickname: String?
    @NSManaged public var notes: String?
    @NSManaged public var phone: String?
    @NSManaged public var relationshipsJSON: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var avatarURL: String?
    @NSManaged public var avatarColor: String?
    @NSManaged public var isStarred: Bool
    @NSManaged public var gender: String?
    @NSManaged public var genderType: String?
    @NSManaged public var howYouMet: String?
    @NSManaged public var stayInTouchFrequency: Int32
    @NSManaged public var stayInTouchTriggerDate: Date?
    @NSManaged public var foodPreferences: String?
    @NSManaged public var contactDescription: String?

}

extension ContactEntity : Identifiable {
    
    var relationships: [Relationship] {
        guard let relationshipsJSON = relationshipsJSON,
              let data = relationshipsJSON.data(using: .utf8) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode([Relationship].self, from: data)
        } catch {
            print("❌ Failed to decode relationships JSON for contact \(id): \(error)")
            return []
        }
    }
    
    func setRelationships(_ relationships: [Relationship]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(relationships)
            self.relationshipsJSON = String(data: data, encoding: .utf8)
        } catch {
            print("❌ Failed to encode relationships for contact \(id): \(error)")
            self.relationshipsJSON = nil
        }
    }
}