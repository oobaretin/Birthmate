import XCTest
@testable import Birthmate

final class WikiFormattingTests: XCTestCase {
    func testPlainTextStripsHTML() {
        let html = #"<span lang="en"><span class="mw-page-title-main">Malik Nabers</span></span>"#
        XCTAssertEqual(WikiFormatting.plainText(from: html), "Malik Nabers")
    }

    func testPlainTextDecodesEntities() {
        let html = "Tom &amp; Jerry&#39;s"
        XCTAssertEqual(WikiFormatting.plainText(from: html), "Tom & Jerry's")
    }

    func testEventYearFromField() {
        let item = OnThisDayItem(text: "Something happened", year: 1969, pages: nil)
        XCTAssertEqual(WikiFormatting.eventYear(for: item), 1969)
    }

    func testIsLivingWhenNoDeathNote() {
        let item = OnThisDayItem(text: "Jane Doe, American singer", year: 1990, pages: nil)
        XCTAssertTrue(WikiFormatting.isLiving(item))
    }

    func testIsNotLivingWhenDeathNotePresent() {
        let item = OnThisDayItem(text: "John Doe, writer (died 2020)", year: 1940, pages: nil)
        XCTAssertFalse(WikiFormatting.isLiving(item))
    }

    func testShareTextForBirth() {
        let item = OnThisDayItem(text: "Ada Lovelace, mathematician", year: 1815, pages: nil)
        let text = WikiFormatting.shareText(for: item, dateLabel: "December 10", isBirth: true)
        XCTAssertTrue(text.contains("Ada Lovelace"))
        XCTAssertTrue(text.contains("December 10"))
    }

    func testWikiImageURLUpgradesHTTPCommonsLink() {
        let raw = "http://commons.wikimedia.org/wiki/Special:FilePath/Macaulay%20Culkin%20-%20Home%20Alone%2035th.jpg"
        let resolved = WikiImageURL.resolved(raw)
        XCTAssertEqual(
            resolved,
            "https://commons.wikimedia.org/wiki/Special:FilePath/Macaulay%20Culkin%20-%20Home%20Alone%2035th.jpg?width=330"
        )
    }

    func testWikiImageURLLeavesDirectUploadURLUnchanged() {
        let raw = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Macaulay_Culkin.jpg/330px-Macaulay_Culkin.jpg"
        XCTAssertEqual(WikiImageURL.resolved(raw), raw)
    }

    func testWikipediaTitleEncodingUsesUnderscores() {
        let encoded = WikipediaTitleEncoding.apiPath(for: "Patrick Williams (basketball)")
        XCTAssertEqual(encoded, "Patrick_Williams_(basketball)")
    }
}
