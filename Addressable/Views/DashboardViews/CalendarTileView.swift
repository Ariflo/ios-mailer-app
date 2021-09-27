//
//  CalendarTileView.swift
//  Addressable
//
//  Created by Ari on 6/5/21.
//

import SwiftUI

struct CalendarTileView: View {
    var date: String?

    var body: some View {
        VStack(spacing: 0) {
            Text(getFormattedTargetDropMonth())
                .font(Font.custom("Silka-Bold", size: 8))
                .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                .foregroundColor(Color.white)
                .textCase(.uppercase)
                .background(Color.addressableBlack)
            Text(getFormattedTargetDropDay())
                .font(Font.custom("Silka-Semibold", size: 16))
                .foregroundColor(Color.black)
        }
        .border(width: 1, edges: [.bottom, .top, .leading, .trailing], color: Color.gray.opacity(0.2))
    }
    private func getFormattedTargetDropMonth() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }
    private func getFormattedTargetDropDay() -> String {
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "d"

        return dateFormatterPrint.string(from: getTargetDropDateObject())
    }
    private func getTargetDropDateObject() -> Date {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatterGet.date(from: date ?? "") {
            return date
        } else {
            return Date()
        }
    }
}
#if DEBUG
struct CalendarTileView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarTileView(date: "2020-06-18")
    }
}
#endif
