<?php

// Create connection
$conn = mysqli_connect(getenv("DB_HOST"),getenv("DB_USER"),getenv("DB_PASSWORD"),getenv("DB_DATABASE"));
// Check connection
if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}
?>
