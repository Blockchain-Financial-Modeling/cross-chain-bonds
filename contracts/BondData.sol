// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract BondData {
    struct Bond {
        string isin;
        string name;
        string symbol;
        address currency;
        uint256 denomination;
        uint256 issueVolume;
        uint256 couponRate;
        uint256 issueDate;
        uint256 maturityDate;
    }

    struct Issuer {
        address account;
        string logoURI;
        string name;
        string country;
        string category;
        string creditRating;
        uint256 carbonCredit;
    }
}