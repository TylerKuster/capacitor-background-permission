const typescript = require('@rollup/plugin-typescript');
const { nodeResolve } = require('@rollup/plugin-node-resolve');

module.exports = [
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/plugin.cjs.js',
      format: 'cjs',
      sourcemap: true,
      inlineDynamicImports: true,
    },
    external: ['@capacitor/core'],
    plugins: [
      typescript({
        tsconfig: './tsconfig.json',
      }),
      nodeResolve(),
    ],
  },
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/esm/index.js',
      format: 'es',
      sourcemap: true,
      inlineDynamicImports: true,
    },
    external: ['@capacitor/core'],
    plugins: [
      typescript({
        tsconfig: './tsconfig.json',
      }),
      nodeResolve(),
    ],
  },
];

