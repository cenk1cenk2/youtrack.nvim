use openapiv3::OpenAPI;

fn main() {
    let src = "./openapi.json";
    // println!("cargo:rerun-if-changed={}", src);
    let file = std::fs::File::open(src).unwrap();
    let mut spec: OpenAPI = serde_json::from_reader(file).unwrap();
    let mut generator = progenitor::Generator::default();

    for (name, path) in spec.paths.paths.iter_mut() {
        if let openapiv3::ReferenceOr::Item(ref mut p) = path {
            if p.head.is_some() {
                p.head.as_mut().unwrap().operation_id = generate_operation_id("head", name);
            }
            if p.get.is_some() {
                p.get.as_mut().unwrap().operation_id = generate_operation_id("get", name);
            }
            if p.post.is_some() {
                p.post.as_mut().unwrap().operation_id = generate_operation_id("post", name);
            }
            if p.put.is_some() {
                p.put.as_mut().unwrap().operation_id = generate_operation_id("put", name);
            }
            if p.patch.is_some() {
                p.patch.as_mut().unwrap().operation_id = generate_operation_id("put", name);
            }
            if p.delete.is_some() {
                p.delete.as_mut().unwrap().operation_id = generate_operation_id("delete", name);
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
