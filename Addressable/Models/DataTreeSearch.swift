//
//  DataTreeSearch.swift
//  Addressable
//
//  Created by Ari on 5/18/21.
//

import Foundation

// MARK: - dataTreeSearchCriteriaWrapper
struct DataTreeSearchCriteriaWrapper: Codable {
    let dataTreeSearchCriteria: DataTreeSearchCriteria

    enum CodingKeys: String, CodingKey {
        case dataTreeSearchCriteria = "data_tree_search_default_criteria"
    }
}

// MARK: - DataTreeSearchCriteria
struct DataTreeSearchCriteria: Codable {
    var minValue, maxValue: Int
    var includeValue: Bool
    var minBedCount, maxBedCount: Int
    var includeBedCount: Bool
    var minBathCount, maxBathCount: Int
    var includeBathCount: Bool
    var minBuildingArea, maxBuildingArea: Int
    var includeBuildingArea: Bool
    var minYearBuilt, maxYearBuilt: Int
    var includeYearBuilt: Bool
    var minLotSize, maxLotSize: Int
    var includeLotSize, landUseSingleFamily, landUseMultiFamily, landUseCondos: Bool
    var landUseVacantLot: Bool
    var minPercentEquity, maxPercentEquity: Int
    var includePercentEquity: Bool
    var minYearsOwned, maxYearsOwned: Int
    var includeYearsOwned, ownerOccupiedOccupied, ownerOccupiedAbsentee: Bool
    var zipcodes: String
    var includeZipcodes: Bool
    var city: String
    var includeCities: Bool

    enum CodingKeys: String, CodingKey {
        case minValue = "min_value"
        case maxValue = "max_value"
        case includeValue = "include_value"
        case minBedCount = "min_bed_count"
        case maxBedCount = "max_bed_count"
        case includeBedCount = "include_bed_count"
        case minBathCount = "min_bath_count"
        case maxBathCount = "max_bath_count"
        case includeBathCount = "include_bath_count"
        case minBuildingArea = "min_building_area"
        case maxBuildingArea = "max_building_area"
        case includeBuildingArea = "include_building_area"
        case minYearBuilt = "min_year_built"
        case maxYearBuilt = "max_year_built"
        case includeYearBuilt = "include_year_built"
        case minLotSize = "min_lot_size"
        case maxLotSize = "max_lot_size"
        case includeLotSize = "include_lot_size"
        case landUseSingleFamily = "land_use_single_family"
        case landUseMultiFamily = "land_use_multi_family"
        case landUseCondos = "land_use_condos"
        case landUseVacantLot = "land_use_vacant_lot"
        case minPercentEquity = "min_percent_equity"
        case maxPercentEquity = "max_percent_equity"
        case includePercentEquity = "include_percent_equity"
        case minYearsOwned = "min_years_owned"
        case maxYearsOwned = "max_years_owned"
        case includeYearsOwned = "include_years_owned"
        case ownerOccupiedOccupied = "owner_occupied_occupied"
        case ownerOccupiedAbsentee = "owner_occupied_absentee"
        case zipcodes
        case includeZipcodes = "include_zipcodes"
        case city
        case includeCities = "include_cities"
    }
}
