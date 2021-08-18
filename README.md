## NetworkKit

Lightweight and easy to use network abstraction layer that sufficiently encapsulates URLSession


## Features

- Execute HTTP requests
- Mock responses
- Intercept request/response
- SSL pinning configuration
- **[WIP]** Response custom DispatchQueue
- **[WIP]** Integrated JSON decoder in Response object

## Requirements

- iOS 12+ / macOS 10.14+ / watchOS 5+ / tvOS 12+
- Xcode 11.0+
- Swift 5+

## Installation

### Swift Package Manager

Add this swift package to your project
```
https://auk-tfs.nzlabs.net/tfs/DefaultCollection/Auckland_PD/_git/iOS_NetworkKit
```

## Usage

### NetworkKit configuration

Provide URLSessionConfiguration object to the `NetworkKit` before the actual usage. If no configuration is set, `NetworkKit` will use the default.

```
let config = URLSessionConfiguration()
NetworkKit.shared.setup(with: config)
```

### SSL pinning

SSL pinning can be set up by providing `SSLPinning` object  during `NetworkKit` setup proccess.

```
let config = SSLPingningConfiguration(sslCertificates: [certificate], sslPinningCertificateType: .root)
let sslPinning = SSLPining(sslPinningConfig: config)
NetworkKit.shared.setup(sslPingning: sslPinning)
```

### Creating endpoint

There is an `EndpointType` interface that describes endpoint behaviour such as path, http method, task, mock data, etc. You can use **struct/enum** for the endpoints you create. If you have multiple requests to one specific endpoint, use **enum with cases**. Despite, single request endpoint could be achieved with using **struct**.

```
enum TestEndpoint: EndpointType {
    case accounts
    case transfers
    
    var baseURL: URL {
        return URL(string: "https://example-url")!
    }
    
    var path: String {
        switch self {
        case .accounts:
            return "accounts"
        case .transfers:
            return "transfers"
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: HTTPTask {
        return .requestPlain
    }

    var headers: HTTPHeaders {
        return [:]
    }
    
    var mockResponse: MockResponseType? {
        switch self {
        case .accounts:
            let jsonString = "{ \"message\": \"Accounts response\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        case .transfers:
            let jsonString = "{ \"message\": \"Transfers response\" }\n"
            let data = jsonString.data(using: .utf8)!
            return .response(201, data)
        }
    }
}
```

### HTTPTask parameter

`.requestPlain` type is used for the request where we don't need to attach any data

`.requestData(Data)` type is used to attach `Data` object to request `httpBody`

`.requestJSONEncodable(Encodable)` type is used to attach JSON `Encodable` object to request `httpBody` 

`.requestParameters(_ parameters: Parameters,_ encodingDestination: URLEncoding.Destination)` is used to attach URL encoded string to either `url` or `httpBody` of the request. 

**Note:** it's required to set headers manually to the endpoint for URL encoding or JSON formats. For example:

```
var headers: HTTPHeaders {
    return ["Content-Type": "application/x-www-form-urlencoded"]
}
```

or

```
var headers: HTTPHeaders {
    return ["Content-Type": "application/json"]
}
```

### Creating router

There is an `DefaultNetworkRouter` object that handles endpoint request execution. Every router is bind to the EndpointType. This is primarly done to prevent users from using single router for different endpoints. **Important** each router instance can handle 1 request at a time. if you need to exceute multiple requests simultaneously, create multiple routers for every request.

```
let router = DefaultNetworkRouter<TestEndpoint>()
```

To enable mocks, just simply specify `MockBehavior` parameter in the router constructor.

```
let router = DefaultNetworkRouter<TestEndpoint>(mockBehavior: .immediate)
```

**Note:** if `mockResponse` is not specified in the endpoint, router will crash with fatal error using `.immediate` or `.delayed(_)` `MockBehavior` type.

There is an `Interceptor` interface that should be used for request and response modifications.

```
struct AuthInterceptor: Interceptor {
    func prepare(_ request: inout URLRequest) {
        request.addValue("Bearer token1", forHTTPHeaderField: "Authorization")
    }

    func process(_ result: inout Result<Response, NetworkError>) {
        guard case .success(let response) = result else {
            return
        }
        var anyHashableHeaders = response.httpURLResponse?.allHeaderFields ?? [AnyHashable: Any]()
        anyHashableHeaders["Authorization"] = "Bearer token2"
        guard let headers = anyHashableHeaders as? [String: String] else {
            return
        }
        let httpURLResponse = HTTPURLResponse(url: response.urlRequest.url!,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: headers)
        let newResponse = Response(urlRequest: response.urlRequest, data: response.data!, httpURLResponse: httpURLResponse)
        result = .success(newResponse)
    }
}
```

You can pass array of interceptors to the router constructor.

```
let router = DefaultNetworkRouter<TestEndpoint>(interceptors: [authInterceptor], mockBehavior: .immediate)
```

### Request execution

Call **execute** method for router object to run your request. You are going to get result of `Result<Response, NetworkError>)` type. `Response` object contains `URLRequest`, `Data` and `HTTPURLResponse` objects.

```
router.execute(endpoint: TestEndpoint.test, completion: { result in
    switch result {
    case .success(let response):
        // handle response
    case .failure(let error):
        // handle error
    }
})
```

To decode JSON response, use Swift `JSONDecoder`.

```
let decoder = JSONDecoder()
let object = try decoder.decode(Object.self, response.data)
```

You can filter the response by status codes range, or filter successful status codes only by calling `filterSuccessfulStatusCodes()` method.

```
do {
    try response.filterSuccessfulStatusCodes()
} ctach let error {
    // handle error
}
```

To cancel request, just simply call **cancel** method for router object. By cancelling the request, you're going to recieved `NSURLErrorDomain` error.

```
router.cancel()
```

### Error handling

There is a `NetworkError` type error that you can recieve during request execution. If you need to handle one particular error case, you can use **guard case** statement.

```
guard case .underlying(let networkError, let response) = error else {
    return
}
```

Use `errorDescription` variable of `NetworkError` to print localised description.

```
print(error.errorDescription)
```

Read `NetworkError` documentation for more details. 
