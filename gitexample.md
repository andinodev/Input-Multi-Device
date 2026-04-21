# Guía Básica de Comandos Git

A continuación te explico el flujo normal para guardar tus cambios (hacer un "commit"), subirlos a un repositorio remoto (hacer "push") y cómo moverte entre ramas (hacer "checkout").

## 1. Preparar los cambios (`git add`)

Cuando modificas o creas nuevos archivos en tu proyecto, Git nota que hay cambios, pero no los prepara automáticamente para guardarlos. Tienes que decirle explícitamente qué cambios quieres preparar (esto se conoce como pasarlos al _Staging Area_).

```bash
git add .
```

- **¿Qué significa?**: El punto `.` significa "todo". Este comando le dice a Git: _"Prepara todos los archivos modificados, borrados o creados nuevos en la carpeta actual y en sus subrutas para el próximo guardado"_.
- **Alternativa**: Si solo quieres agregar un archivo específico, puedes usar `git add nombre_del_archivo.txt`.

## 2. Guardar los cambios (`git commit`)

Una vez que tus archivos están preparados (después del `git add`), necesitas "empaquetarlos" o "tomarles una foto" y ponerles un mensaje descriptivo para saber qué cambiaste.

```bash
git commit -m "Añadida la escena de opciones y botones"
```

- **¿Qué significa?**:
  - `git commit`: Crea un punto en el historial con los cambios que preparaste con `git add`.
  - `-m`: Viene de "message" (mensaje).
  - `"..."`: Es el texto que describe los cambios. **Siempre debe ser claro y descriptivo** para que tus compañeros de equipo (o tu yo del futuro) sepan qué modificaste.

## 3. Subir los cambios a internet (`git push`)

Los comandos anteriores (`add` y `commit`) solo guardan los cambios **localmente**, es decir, en tu propio disco duro. Para que esos cambios lleguen a internet (GitHub, GitLab, Bitbucket) y otros puedan trabajar con ellos, necesitas pushearlo.

```bash
git push
```

- **¿Qué significa?**: Sube todos los `commits` que tienes guardados en tu rama local hacia la misma rama en el servidor remoto.
- **Dato útil**: Si acabas de crear una rama en tu computadora y es la primera vez que la subes, Git te interrumpirá y te pedirá que uses un comando ligeramente distinto para "crearle el gemelo" en internet, normalmente: `git push -u origin nombre_de_la_rama`.

## 4. Cambiar de rama (`git checkout`)

Las ramas (_branches_) permiten trabajar en características separadas del código, así puedes experimentar sin correr el riesgo de romper la rama principal (la que suele llamarse `main` o `master`).

```bash
git checkout mi_rama
```

- **¿Qué significa?**: Le dice a Git que quieres cambiarte a la rama llamada `mi_rama`. Tus archivos en el disco duro cambiarán instantáneamente para mostrarte el código tal cual está en esa otra rama.
- **Crear una rama nueva**: Si la rama todavía no existe y quieres crearla y moverte a ella en un solo paso, le sumas la letra `-b` (de branch):
  ```bash
  git checkout -b mi_nueva_rama
  ```
  > [!NOTE]
  > **El nuevo comando:** En las versiones modernas de Git, el comando `checkout` se ha dividido en dos para no ser tan confuso. Ahora se sugiere usar `git switch mi_rama` para saltar de ramas o `git switch -c mi_nueva_rama` para crearla y saltar. Ambos (`checkout` y `switch`) hacen casi lo mismo y son correctos.

## 5. Traer los últimos cambios (`git pull`)

Antes de empezar a trabajar o antes de subir tus cambios, es muy importante asegurarte de que tienes la versión más reciente del código que está en internet.

```bash
git pull
```

- **¿Qué significa?**: Descarga el historial más reciente desde el servidor remoto y lo actualiza en tu código local.
- **Nota**: Si alguien más modificó las mismas líneas de código que tú, pueden generarse "conflictos" (`merge conflicts`). En ese caso, Git te pedirá que elijas con qué versión de código quedarte.

## 6. Juntar los cambios de otra rama (`git merge`)

Si estabas trabajando en una rama separada (por ejemplo, `mi_nueva_rama`) y ya terminaste tu característica, querrás llevar esos cambios a la rama principal (suele ser `main` o `develop`).

Para hacerlo, primero debes moverte a la rama que va a _recibir_ los cambios:

```bash
git checkout main
```

_(Es buena práctica hacer `git pull` en este momento para asegurar que tu rama principal esté actualizada)._

Luego, fusionas o "absorbes" la otra rama:

```bash
git merge mi_nueva_rama
```

- **¿Qué significa?**: Toma todo el trabajo terminado en `mi_nueva_rama` y lo incorpora a la rama en la que te encuentras (`main`).

---

### Resumen del Flujo de Trabajo Diario:

```bash
# 0. (Opcional pero recomendado) Traigo los últimos cambios de mis compañeros:
git pull

# 1. Hago cambios en mi código...

# 2. Reviso y agrego todos mis archivos cambiados:
git add .

# 3. Guardo mis cambios en el historial de forma descriptiva:
git commit -m "Solución de bug en CheckButton de opciones"

# 4. Los subo al repositorio en línea para que mi equipo lo tenga:
git push
```
