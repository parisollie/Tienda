//
//  ContentView.swift
//  Tienda
//
//  Created by Paul F on 27/07/25.
//

import SwiftUI

/// Main view displaying a searchable product grid and a toolbar cart button
struct ContentView: View {
    // MARK: - State Variables
    @State private var selectedProduct: Product?
    @State private var showDetail = false
    @State private var cart: [Product] = []
    @State private var showCart = false
    @State private var searchText = ""
    @Namespace var animation // For matched geometry effects

    // Filter products based on search text
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Define grid layout for product cards
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 20)]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Refined background gradient for a modern look
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Scrollable grid of products
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product, onAddToCart: {
                                withAnimation {
                                    cart.append(product)
                                }
                            })
                            .onTapGesture {
                                selectedProduct = product
                                showDetail = true
                            }
                        }
                    }
                    .padding()
                }
                
                // Popup cart overlay
                if showCart {
                    CartPopup(cart: cart, showCart: $showCart, animation: animation)
                        .zIndex(2)
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: showCart)
                }
            }
            .navigationTitle("Trending Products")
            .toolbar {
                // Toolbar cart button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation { showCart = true }
                    }) {
                        CartButton(counter: cart.count)
                    }
                }
            }
            // Search bar to filter products
            .searchable(text: $searchText, prompt: "Search products")
            // Present product details as a sheet
            .sheet(isPresented: $showDetail) {
                if let product = selectedProduct {
                    ProductDetailView(product: product)
                }
            }
        }
        .accentColor(.purple)
    }
}

/// A card view representing an individual product with image, rating, and add-to-cart functionality
struct ProductCard: View {
    let product: Product
    let onAddToCart: () -> Void
    
    // MARK: - Animation & State Variables
    @State private var isLiked = false
    @State private var animateLike = false
    @State private var showAddedOverlay = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image with a like button overlay
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 150, height: 200)
                .cornerRadius(15)
                .overlay(
                    // White border for better image definition
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                
                // Like button with a spring animation
                Button {
                    withAnimation(.spring()) {
                        isLiked.toggle()
                        animateLike = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animateLike = false
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .scaleEffect(animateLike ? 1.2 : 1.0)
                }
                .padding(8)
            }
            
            // Product name, price, and rating
            Text(product.name)
                .font(.headline)
                .lineLimit(1)
            Text("$\(product.price, specifier: "%.2f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Rating: \(product.rating, specifier: "%.1f") ⭐️")
                .font(.caption)
                .foregroundColor(.orange)
            
            // "Add to Cart" button with overlay animation
            Button(action: {
                onAddToCart()
                withAnimation(.easeInOut) {
                    showAddedOverlay = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut) {
                        showAddedOverlay = false
                    }
                }
            }) {
                Text("Add to Cart")
                    .font(.caption)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .overlay(
                Text("Added!")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.green)
                    .opacity(showAddedOverlay ? 1 : 0)
                    .scaleEffect(showAddedOverlay ? 1.2 : 0.5)
            )
        }
        .padding()
        .background(
            // Card-style background with rounded corners and shadow
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.gray.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

/// Cart button view with an optional matched geometry effect for seamless animation
struct CartButton: View {
    let counter: Int
    var useMatched: Bool = false
    var animation: Namespace.ID? = nil
    
    var body: some View {
        Group {
            Image(systemName: "cart")
                .font(.title2)
                .padding(8)
                .background(Circle().fill(Color.white))
                .overlay(
                    Group {
                        if counter > 0 {
                            Text("\(counter)")
                                .font(.caption2)
                                .padding(5)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                                .transition(.scale)
                        }
                    }
                )
        }
        .modifier(MatchedGeometryModifier(useMatched: useMatched, animation: animation))
    }
}

/// View modifier to conditionally apply a matched geometry effect
struct MatchedGeometryModifier: ViewModifier {
    let useMatched: Bool
    let animation: Namespace.ID?
    
    func body(content: Content) -> some View {
        if useMatched, let animation = animation {
            content.matchedGeometryEffect(id: "cartButton", in: animation)
        } else {
            content
        }
    }
}

/// Detail view for a selected product including description, rating, and a "Buy Now" button
struct ProductDetailView: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 16) {
            // The product image is constrained not to exceed the screen width.
            AsyncImage(url: URL(string: product.imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else if phase.error != nil {
                    Color.red
                } else {
                    ProgressView()
                }
            }
            // Limit the width to the device's width minus some padding and a fixed height.
            .frame(maxWidth: UIScreen.main.bounds.width - 32, maxHeight: 300)
            .cornerRadius(15)
            .padding()
            
            Text(product.name)
                .font(.largeTitle)
                .bold()
            
            Text("$\(product.price, specifier: "%.2f")")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("Rating: \(product.rating, specifier: "%.1f") ⭐️")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text(product.description)
                .font(.body)
                .padding()
            
            Spacer()
            
            Button(action: {
                // Simulate a purchase action
            }) {
                Text("Buy Now")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

/// Popup view for displaying the shopping cart contents as an overlay
struct CartPopup: View {
    let cart: [Product]
    @Binding var showCart: Bool
    var animation: Namespace.ID
    
    var body: some View {
        ZStack {
            // Dimmed background dismisses the popup when tapped
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showCart = false }
                }
            VStack(spacing: 0) {
                // Popup header with matched geometry effect for the cart icon
                HStack {
                    CartButton(counter: cart.count, useMatched: true, animation: animation)
                        .onTapGesture {
                            withAnimation { showCart = false }
                        }
                    Spacer()
                    Text("Your Cart")
                        .font(.headline)
                        .padding()
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                // List of cart items
                List(cart) { product in
                    HStack {
                        AsyncImage(url: URL(string: product.imageURL)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else if phase.error != nil {
                                Color.red.frame(width: 60, height: 60)
                            } else {
                                ProgressView().frame(width: 60, height: 60)
                            }
                        }
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Rating: \(product.rating, specifier: "%.1f") ⭐️")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 300)
                
                // Close button for the cart popup
                Button(action: {
                    withAnimation { showCart = false }
                }) {
                    Text("Close")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
}

/// Model representing a product with description and rating
struct Product: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let price: Double
    let imageURL: String
    let description: String
    let rating: Double
}

// Sample product data using Picsum with seeded URLs for consistency
let products = [
    Product(
        name: "Designer Handbag",
        price: 599.99,
        imageURL: "https://picsum.photos/seed/handbag/300/200",
        description: "Elegant designer handbag made from premium leather. Perfect for any occasion.",
        rating: 4.5
    ),
    Product(
        name: "Sports Shoes",
        price: 899.50,
        imageURL: "https://picsum.photos/seed/sportsshoes/300/200",
        description: "High-performance sports shoes that are both comfortable and durable.",
        rating: 4.2
    ),
    Product(
        name: "Wireless Headphones",
        price: 1299.00,
        imageURL: "https://picsum.photos/seed/headphones/300/200",
        description: "Experience crystal clear sound with these noise-cancelling wireless headphones.",
        rating: 4.7
    ),
    Product(
        name: "Sunglasses",
        price: 349.95,
        imageURL: "https://picsum.photos/seed/sunglasses/300/200",
        description: "Stylish sunglasses offering full UV protection with a trendy design.",
        rating: 4.3
    ),
    Product(
        name: "Smart Watch",
        price: 1599.00,
        imageURL: "https://picsum.photos/seed/smartwatch/300/200",
        description: "Modern smart watch with advanced health tracking features.",
        rating: 4.6
    ),
    Product(
        name: "Leather Wallet",
        price: 249.99,
        imageURL: "https://picsum.photos/seed/wallet/300/200",
        description: "Compact and stylish leather wallet with multiple compartments.",
        rating: 4.1
    )
]

#Preview {
    ContentView()
}
