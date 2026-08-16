"use client";

import { useEffect, useState } from "react";

interface ApiProduct {
  name: string;
  title: string;
  description: string;
  version: string;
  path: string;
}

interface OpenApiSpec {
  info: {
    title: string;
    description: string;
    version: string;
  };
  paths: Record<string, Record<string, unknown>>;
  components?: {
    schemas?: Record<string, unknown>;
  };
}

const API_BASE = "http://localhost:8080";

export default function ApiExplorer() {
  const [products, setProducts] = useState<ApiProduct[]>([]);
  const [selectedProduct, setSelectedProduct] = useState<string | null>(null);
  const [spec, setSpec] = useState<OpenApiSpec | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetch(`${API_BASE}/openapi`)
      .then((res) => res.json())
      .then((data) => {
        // API returns array of arrays, convert to objects
        const parsed = data.map((item: string[][]) => {
          const obj: Record<string, string> = {};
          item.forEach(([key, value]) => {
            obj[key] = value;
          });
          return obj as unknown as ApiProduct;
        });
        setProducts(parsed);
        setLoading(false);
      })
      .catch((err) => {
        setError(`Failed to connect to API at ${API_BASE}: ${err.message}`);
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    if (selectedProduct) {
      const product = products.find((p) => p.name === selectedProduct);
      if (product) {
        setLoading(true);
        fetch(`${API_BASE}${product.path}`)
          .then((res) => res.json())
          .then((data) => {
            setSpec(data);
            setLoading(false);
          })
          .catch((err) => {
            setError(`Failed to load spec: ${err.message}`);
            setLoading(false);
          });
      }
    }
  }, [selectedProduct, products]);

  const endpoints = spec ? Object.entries(spec.paths) : [];
  const schemas = spec?.components?.schemas
    ? Object.keys(spec.components.schemas)
    : [];

  return (
    <div className="min-h-screen bg-black text-white p-8 font-mono">
      <header className="mb-8">
        <h1 className="text-3xl font-bold text-cyan-400">
          {"// straylight // api explorer //"}
        </h1>
        <p className="text-zinc-500 mt-2">
          Live OpenAPI specs from the Haskell backend
        </p>
      </header>

      {error && (
        <div className="bg-red-900/50 border border-red-500 rounded p-4 mb-8">
          <p className="text-red-400">{error}</p>
          <p className="text-zinc-500 text-sm mt-2">
            Make sure the API server is running: <code>result/bin/straylight-api</code>
          </p>
        </div>
      )}

      {loading && !error && (
        <div className="text-zinc-500">Loading...</div>
      )}

      {!loading && !error && (
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Product List */}
          <div className="lg:col-span-1">
            <h2 className="text-lg font-bold text-zinc-400 mb-4">Products</h2>
            <div className="space-y-2">
              {products.map((product) => (
                <button
                  type="button"
                  key={product.name}
                  onClick={() => setSelectedProduct(product.name)}
                  className={`w-full text-left p-3 rounded border transition-colors ${
                    selectedProduct === product.name
                      ? "bg-cyan-900/30 border-cyan-500 text-cyan-400"
                      : "bg-zinc-900/50 border-zinc-800 hover:border-zinc-600"
                  }`}
                >
                  <div className="font-bold">{product.title}</div>
                  <div className="text-xs text-zinc-500 mt-1">
                    {product.description}
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Spec Details */}
          <div className="lg:col-span-3">
            {spec && (
              <>
                <div className="mb-8">
                  <h2 className="text-2xl font-bold text-cyan-400">
                    {spec.info.title}
                  </h2>
                  <p className="text-zinc-400 mt-2">{spec.info.description}</p>
                  <p className="text-zinc-600 text-sm mt-1">
                    Version: {spec.info.version}
                  </p>
                </div>

                {/* Endpoints */}
                <div className="mb-8">
                  <h3 className="text-lg font-bold text-zinc-400 mb-4">
                    Endpoints ({endpoints.length})
                  </h3>
                  <div className="space-y-2">
                    {endpoints.map(([path, methods]) => (
                      <div
                        key={path}
                        className="bg-zinc-900/50 border border-zinc-800 rounded p-3"
                      >
                        <code className="text-green-400">{path}</code>
                        <div className="flex gap-2 mt-2">
                          {Object.keys(methods as object).map((method) => (
                            <span
                              key={method}
                              className={`text-xs px-2 py-1 rounded uppercase font-bold ${
                                method === "get"
                                  ? "bg-blue-900/50 text-blue-400"
                                  : method === "post"
                                  ? "bg-green-900/50 text-green-400"
                                  : method === "put"
                                  ? "bg-yellow-900/50 text-yellow-400"
                                  : method === "delete"
                                  ? "bg-red-900/50 text-red-400"
                                  : "bg-zinc-800 text-zinc-400"
                              }`}
                            >
                              {method}
                            </span>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Schemas */}
                <div>
                  <h3 className="text-lg font-bold text-zinc-400 mb-4">
                    Schemas ({schemas.length})
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {schemas.map((schema) => (
                      <span
                        key={schema}
                        className="bg-purple-900/30 text-purple-400 px-3 py-1 rounded text-sm border border-purple-800"
                      >
                        {schema}
                      </span>
                    ))}
                  </div>
                </div>
              </>
            )}

            {!spec && !loading && (
              <div className="text-zinc-500">
                Select a product to view its API spec
              </div>
            )}
          </div>
        </div>
      )}

      <footer className="mt-16 pt-8 border-t border-zinc-800 text-zinc-600 text-sm">
        <p>
          API Server: <code>{API_BASE}</code> | Frontend:{" "}
          <code>http://localhost:3000</code>
        </p>
      </footer>
    </div>
  );
}
