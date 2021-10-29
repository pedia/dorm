// CREATE TABLE `bullet` (
//   `bid` int NOT NULL AUTO_INCREMENT,
//   `ctime` datetime DEFAULT NULL,
//   `close_time` datetime DEFAULT NULL,
//   `tid` int DEFAULT NULL,
//   `side` tinyint(1) NOT NULL,
//   `price` float NOT NULL,
//   `close_price` float NOT NULL,
//   `volume` int NOT NULL,
//   `close_volume` int NOT NULL,
//   PRIMARY KEY (`bid`),
//   KEY `tid` (`tid`),
//   CONSTRAINT `bullet_ibfk_1` FOREIGN KEY (`tid`) REFERENCES `trade` (`tid`)
// ) ENGINE=InnoDB AUTO_INCREMENT=287 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci