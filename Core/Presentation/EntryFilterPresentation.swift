enum EntryFilterPresentation {
    static func emptyMessage(for filter: EntryFilter) -> String {
        switch filter {
        case .eksiseyler:
            return "bu başlık ekşi şeyler'de yer almıyor"
        default:
            return "bu filtrede entry bulunamadı"
        }
    }
}
