use axum::{response::Html, routing::get, Router};
use std::env;

async fn health() -> Html<&'static str> {
    Html("ok")
}

pub fn http_router() -> Router {
    Router::new().route("/health", get(health))
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let app = http_router();
    let endpoint = env::var("ENDPOINT").unwrap_or_else(|_| "0.0.0.0:8080".to_owned());
    let addr = endpoint.parse()?;

    println!("listening on {}", addr);

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();

    Ok(())
}

#[cfg(test)]
mod tests {
    use axum::{
        body::Body,
        http::{self, StatusCode},
    };
    use tower::ServiceExt;

    use super::*;

    #[tokio::test]
    async fn test_health() {
        let app = http_router();

        let response = app
            .oneshot(
                http::Request::builder()
                    .method(http::Method::GET)
                    .uri("/health")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);

        let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
        assert_eq!(&body[..], b"ok");
    }
}
