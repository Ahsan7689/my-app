# Blueprint

## Overview

This document outlines the key features and design of the E-commerce App. The app allows users to browse products, add them to their cart, and place orders. Admins can manage products and orders through a dedicated dashboard.

## Features

### User Features

*   **Authentication:** Users can sign up and log in using email and password or Google Sign-In.
*   **Product Browsing:** Users can view a list of products, filter them by category, and sort them by price, rating, and name.
*   **Product Details:** Users can view detailed information about a single product, including its description, images, price, and reviews.
*   **Shopping Cart:** Users can add products to their shopping cart and manage the items in it.
*   **Checkout:** Users can place orders and provide shipping information.
*   **Order History:** Users can view their past orders.
*   **Product Reviews:** Users can submit reviews and ratings for products they have purchased.

### Admin Features

*   **Dashboard:** Admins have a dashboard to view key analytics, such as total income, total orders, and total users.
*   **Product Management:** Admins can add, edit, and delete products.
*   **Order Management:** Admins can view and manage all orders, including updating their status.
*   **Stock Management:** The stock of a product is automatically decreased when an order is placed.
*   **Image Upload:** Admins can upload product images from their local machine or by providing an image URL.

## Design

### UI/UX

*   The app uses a modern and clean design, with a focus on user experience.
*   The primary color scheme is based on pink, which creates a vibrant and engaging look and feel.
*   The UI is responsive and adapts to different screen sizes.

### Architecture

*   The app follows a provider pattern for state management, with a clear separation of concerns between the UI, business logic, and data layers.
*   The app uses Firebase for backend services, including Authentication, Firestore, and Storage.

## Current Plan

*   **Implement Stock Management:**
    *   [x] Add an `updateStock` method to the `ProductProvider`.
    *   [x] Modify the `OrderProvider` to call `updateStock` when an order is placed.
    *   [x] Use a transaction to ensure atomicity.
*   **Enhance Admin Image Upload:**
    *   [x] Add the `firebase_storage` dependency.
    *   [x] Update the `ProductProvider` to handle image uploads to Firebase Storage.
    *   [x] Modify the `AddProductScreen` to allow admins to upload an image or provide an image URL.
