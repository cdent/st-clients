-- phpMyAdmin SQL Dump
-- version 2.6.1-rc1
-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Jun 02, 2005 at 01:10 PM
-- Server version: 4.0.22
-- PHP Version: 4.3.10
-- 
-- Database: `Qatzilla`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `Counts`
-- 

DROP TABLE IF EXISTS `Counts`;
CREATE TABLE IF NOT EXISTS `Counts` (
  `section_id` int(10) unsigned NOT NULL default '0',
  `report_id` int(10) unsigned NOT NULL default '0',
  `os_id` int(10) unsigned NOT NULL default '0',
  `status` varchar(64) NOT NULL default '',
  `count` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`section_id`,`report_id`,`os_id`,`status`),
  KEY `os_id` (`os_id`),
  KEY `report_id_2` (`report_id`,`os_id`,`status`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `OS`
-- 

DROP TABLE IF EXISTS `OS`;
CREATE TABLE IF NOT EXISTS `OS` (
  `os_id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`os_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `Products`
-- 

DROP TABLE IF EXISTS `Products`;
CREATE TABLE IF NOT EXISTS `Products` (
  `product_id` int(10) unsigned NOT NULL auto_increment,
  `product_xid` varchar(255) NOT NULL default '',
  `name` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`product_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `Reports`
-- 

DROP TABLE IF EXISTS `Reports`;
CREATE TABLE IF NOT EXISTS `Reports` (
  `report_id` int(10) unsigned NOT NULL auto_increment,
  `product_id` int(10) unsigned NOT NULL default '0',
  `name` varchar(255) NOT NULL default '',
  `change` int(10) unsigned NOT NULL default '0',
  `date` timestamp(14) NOT NULL,
  PRIMARY KEY  (`report_id`),
  KEY `product_id` (`product_id`),
  KEY `date` (`date`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `Test_Cases`
-- 

DROP TABLE IF EXISTS `Test_Cases`;
CREATE TABLE IF NOT EXISTS `Test_Cases` (
  `tc_id` int(10) unsigned NOT NULL auto_increment,
  `tc_xid` varchar(100) NOT NULL default '',
  `section_id` int(10) unsigned NOT NULL default '0',
  `os_id` int(10) unsigned NOT NULL default '0',
  `report_id` int(10) unsigned NOT NULL default '0',
  `product_id` int(10) unsigned NOT NULL default '0',
  `status` varchar(64) NOT NULL default 'Untested',
  `comment` text,
  `user` varchar(255) NOT NULL default '',
  `name` varchar(255) NOT NULL default '',
  `tc_xkeys` text,
  PRIMARY KEY  (`tc_id`),
  KEY `product_id` (`product_id`),
  KEY `section_id` (`section_id`),
  KEY `os_id` (`os_id`),
  KEY `report_id` (`report_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `External_Sections`
-- 

DROP TABLE IF EXISTS `External_Sections`;
CREATE TABLE IF NOT EXISTS `External_Sections` (
  `tc_id` int(10) unsigned NOT NULL auto_increment,
  `section_id` varchar(100) NOT NULL default '',
  `os_id` int(10) unsigned NOT NULL default '0',
  `total` int(10) unsigned NOT NULL default '0',
  `pass` int(10) unsigned NOT NULL default '0',
  `fail` int(10) unsigned NOT NULL default '0',
  `url`  varchar(255) NOT NULL default '',
  PRIMARY KEY  (`tc_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

-- 
-- Table structure for table `Test_Sections`
-- 

DROP TABLE IF EXISTS `Test_Sections`;
CREATE TABLE IF NOT EXISTS `Test_Sections` (
  `section_id` int(10) unsigned NOT NULL auto_increment,
  `section_xid` varchar(100) NOT NULL default '',
  `report_id` int(10) unsigned NOT NULL default '0',
  `time` varchar(10) NOT NULL default "0:00",
  `name` varchar(255) NOT NULL default '',
  `tester` varchar(255),
  `filename` varchar(255),
  `priority` varchar(10) default "medium",
  PRIMARY KEY  (`section_id`),
  KEY `report_id` (`report_id`)
) TYPE=InnoDB;

-- 
-- Constraints for dumped tables
-- 

-- 
-- Constraints for table `Counts`
-- 
ALTER TABLE `Counts`
  ADD CONSTRAINT `Counts_ibfk_4` FOREIGN KEY (`section_id`) REFERENCES `Test_Sections` (`section_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `Counts_ibfk_5` FOREIGN KEY (`report_id`) REFERENCES `Reports` (`report_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `Counts_ibfk_6` FOREIGN KEY (`os_id`) REFERENCES `OS` (`os_id`) ON DELETE CASCADE;

-- 
-- Constraints for table `Reports`
-- 
ALTER TABLE `Reports`
  ADD CONSTRAINT `Reports_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- 
-- Constraints for table `Test_Cases`
-- 
ALTER TABLE `Test_Cases`
  ADD CONSTRAINT `Test_Cases_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `Products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `Test_Cases_ibfk_2` FOREIGN KEY (`section_id`) REFERENCES `Test_Sections` (`section_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `Test_Cases_ibfk_3` FOREIGN KEY (`os_id`) REFERENCES `OS` (`os_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `Test_Cases_ibfk_4` FOREIGN KEY (`report_id`) REFERENCES `Reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- 
-- Constraints for table `Test_Sections`
-- 
ALTER TABLE `Test_Sections`
  ADD CONSTRAINT `Test_Sections_ibfk_1` FOREIGN KEY (`report_id`) REFERENCES `Reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;
