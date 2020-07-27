import XCTest

import GCETests

var tests = [XCTestCaseEntry]()
tests += GCETests.allTests()
XCTMain(tests)
