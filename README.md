> [!NOTE] Rama de desarrollo para los LXC de LlamaSwap
> Es una rama para desarrollar y mergear cambios comunes a los backend.


Explicación:
- Cómo los modelos se comportan distinto en cada backend, es mucho más sostenible mantener los cambios en ramas separadas.
- De esta manera puede haber modelos con configuraciones distintas según el backend sin conflicto ni crear más fichero.
- Del mismo modo, algunos modelos sólo funcionan en un backend, y la división ayuda a mantener todo ordenado.