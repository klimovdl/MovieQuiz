import XCTest

final class MovieQuizUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // этот флаг активирует StubQuestionFactory в контроллере
        app.launchArguments += ["-UITesting"]
        app.launch()
    }

    func testScreenCast() throws {
        let yes = app.buttons["Yes"]
        XCTAssertTrue(yes.waitForExistence(timeout: 5))
        yes.tap()
        // Убедимся, что постер всё ещё виден
        let data = app.images["Poster"].screenshot().pngRepresentation
        XCTAssertNotNil(data)
    }

    func testNoButton() throws {
        // 1) Ждём появления первого вопроса
        let poster = app.images["Poster"]
        XCTAssertTrue(poster.waitForExistence(timeout: 5))

        // 2) Убедимся: счётчик = "1/10"
        let index = app.staticTexts["Index"]
        XCTAssertTrue(index.exists)
        XCTAssertEqual(index.label, "1/10")

        // 3) Нажимаем «Нет»
        app.buttons["No"].tap()

        // 4) Ждём появления «2/10»
        let next = app.staticTexts["Index"]
        let exp = expectation(
            for: NSPredicate(format: "label == %@", "2/10"),
            evaluatedWith: next, handler: nil
        )
        wait(for: [exp], timeout: 5)
        XCTAssertEqual(next.label, "2/10")
    }

    func testGameFinish() throws {
        // 1) Ждём первого вопроса
        XCTAssertTrue(app.images["Poster"].waitForExistence(timeout: 5))

        // 2) Отвечаем «Нет» 10 раз
        let no = app.buttons["No"]
        for _ in 1...10 {
            XCTAssertTrue(no.exists)
            no.tap()
            sleep(1)    // даём анимации и stub-фабрике подгрузить след. вопрос
        }

        // 3) Ждём алерт
        let alert = app.alerts["Этот раунд окончен!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))

        // 4) Проверяем заголовок и кнопку
        XCTAssertEqual(alert.staticTexts.element.label, "Этот раунд окончен!")
        XCTAssertTrue(alert.buttons["Попробовать ещё раз"].exists)
    }

    func testAlertDismiss() throws {
        // 1) Завершаем игру точно так же
        XCTAssertTrue(app.images["Poster"].waitForExistence(timeout: 5))
        let no = app.buttons["No"]
        for _ in 1...10 {
            no.tap()
            sleep(1)
        }

        // 2) Ждём алерт
        let alert = app.alerts["Этот раунд окончен!"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))

        // 3) Тапаем «Попробовать ещё раз»
        alert.buttons["Попробовать ещё раз"].tap()

        // 4) Ожидаем закрытия алерта
        XCTAssertFalse(alert.exists)

        // 5) И проверяем, что счётчик снова "1/10"
        let index = app.staticTexts["Index"]
        XCTAssertTrue(index.waitForExistence(timeout: 5))
        XCTAssertEqual(index.label, "1/10")
    }
}
