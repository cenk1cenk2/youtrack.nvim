use http::Method;
use openapiv3::OpenAPI;

fn main() {
    let src = "./openapi.json";
    println!("cargo:rerun-if-changed={}", src);
    let file = std::fs::File::open(src).unwrap();
    let mut spec: OpenAPI = serde_json::from_reader(file).unwrap();
    let mut generator = progenitor::Generator::default();

    for (name, path) in spec.paths.paths.iter_mut() {
        if let openapiv3::ReferenceOr::Item(ref mut p) = path {
            for (method, f) in Vec::from_iter([
                (Method::HEAD.as_str().to_lowercase().as_str(), &mut p.head),
                (Method::GET.as_str().to_lowercase().as_str(), &mut p.get),
                (Method::POST.as_str().to_lowercase().as_str(), &mut p.post),
                (Method::PUT.as_str().to_lowercase().as_str(), &mut p.put),
                (Method::PATCH.as_str().to_lowercase().as_str(), &mut p.patch),
                (
                    Method::DELETE.as_str().to_lowercase().as_str(),
                    &mut p.delete,
                ),
            ]) {
                if f.is_some() {
                    f.as_mut().unwrap().operation_id = generate_operation_id(method, name);
                }
            }
        }
    }

    let tokens = generator.generate_tokens(&spec).unwrap();
    let ast = syn::parse2(tokens).unwrap();
    let content = prettyplease::unparse(&ast);

    let mut out = std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).to_path_buf();
    out.push("codegen.rs");

    std::fs::write(out, content).unwrap();
}

fn generate_operation_id(method: &str, name: &str) -> Option<String> {
    Some(format!(
        "{}_{}",
        name.replace("{", "__").replace("}", "__").replace("/", "_"),
        method,
    ))
}
