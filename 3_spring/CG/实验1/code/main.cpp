#include <glad/glad.h>
#include <GLFW/glfw3.h>

#define IMGUI_IMPL_OPENGL_LOADER_GLAD 
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include <glm/glm.hpp>
#include <glm/ext.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <iostream>
#include <cmath>
#include <vector>
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

// 着色器代码
const char* vertexShaderSource = R"(
    #version 330 core
    layout (location = 0) in vec3 aPos;
    layout (location = 1) in vec3 aNormal;
    
    out vec3 Normal;
    out vec3 FragPos;
    out vec3 GouraudColor; // 新增输出变量
    
    uniform mat4 model;
    uniform mat4 view;
    uniform mat4 projection;
    uniform int shadingModel;
    uniform vec3 lightPos;    // 需要从C++传入
    uniform vec3 viewPos;     // 新增摄像机位置
    uniform vec3 objectColor; // 新增物体颜色
    uniform vec3 lightColor;  // 新增光源颜色

    layout(location = 2) in vec2 aTexCoord;
    out vec2 TexCoord;
    
    void main()
    {
        gl_Position = projection * view * model * vec4(aPos, 1.0);
        FragPos = vec3(model * vec4(aPos, 1.0));
        mat3 normalMatrix = transpose(inverse(mat3(model)));
        Normal = normalMatrix * aNormal; // 只传递法线和位置
        TexCoord = aTexCoord;
    }
)";

const char* fragmentShaderSource = R"(
    #version 330 core
in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoord;
out vec4 FragColor;

uniform vec3 lightPos;
uniform vec3 objectColor;
uniform vec3 lightColor;
uniform int shadingModel;
uniform vec3 viewPos;
uniform sampler2D texture1;
uniform bool useTexture;

void main()
{
    vec3 ambient = vec3(0.0);
    vec3 diffuse = vec3(0.0);
    vec3 specular = vec3(0.0);

    // 公共计算部分
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    vec3 viewDir = normalize(viewPos - FragPos);

    if(shadingModel == 0) { // Lambert
        float diff = max(dot(norm, lightDir), 0.0);
        diffuse = diff * lightColor;
        ambient = 0.1 * lightColor; // 添加基础环境光
    }
    else if(shadingModel == 1) { // Blinn-Phong
        vec3 halfwayDir = normalize(lightDir + viewDir);
        float diff = max(dot(norm, lightDir), 0.0);
        float spec = pow(max(dot(norm, halfwayDir), 0.0), 32.0);
        
        ambient = 0.05 * lightColor;
        diffuse = diff * lightColor;
        specular = 1.5 * spec * lightColor;
    }
    else if(shadingModel == 2) { // Phong
        vec3 reflectDir = reflect(-lightDir, norm);
        float diff = max(dot(norm, lightDir), 0.0);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
        
        ambient = 0.1 * lightColor; // 添加环境光
        diffuse = diff * lightColor;
        specular = 2.0 * spec * lightColor;
    }

    vec3 lighting = (ambient + diffuse + specular);
    vec4 finalColor;

    if(useTexture) {
        vec4 texColor = texture(texture1, TexCoord);
        finalColor = vec4(lighting, 1.0) * texColor;
    } else {
        finalColor = vec4(lighting * objectColor, 1.0);
    }

    FragColor = finalColor;
}
)";


// 地面着色器
const char* groundVertexShaderSource = R"(
    #version 330 core
    layout(location=0) in vec3 aPos;
    uniform mat4 view;
    uniform mat4 projection;
    void main() {
        gl_Position = projection * view * vec4(aPos, 1.0);
    }
)";
const char* groundFragmentShaderSource = R"(
    #version 330 core
    out vec4 FragColor;
    uniform vec3 color;
    void main() {
        FragColor = vec4(color, 1.0);
    }
)";

const char* shadowVertexShaderSource = R"(
    #version 330 core
    layout(location=0) in vec3 aPos;
    uniform mat4 model;
    uniform mat4 shadowProj;
    uniform mat4 view;
    uniform mat4 projection;
    void main() {
        vec4 worldPos = model * vec4(aPos, 1.0);
        vec4 shadowPos = shadowProj * worldPos;
        gl_Position = projection * view * shadowPos;
    }
)";
const char* shadowFragmentShaderSource = R"(
    #version 330 core
    out vec4 FragColor;
    void main() {
        FragColor = vec4(0.0, 0.0, 0.0, 0.5); // 半透明黑色阴影
    }
)";

// 立方体顶点数据
float vertices[] = {
    // 位置             法线              纹理坐标
    // 后侧（Z负方向）
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 0.0f, 0.0f,
     0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 1.0f, 0.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 1.0f, 1.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 1.0f, 1.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f,  0.0f,  0.0f, -1.0f, 0.0f, 0.0f,

    // 前侧（Z正方向）
    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 0.0f, 0.0f,
     0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 1.0f, 0.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 1.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 1.0f, 1.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f,  0.0f,  0.0f, 1.0f, 0.0f, 0.0f,

    // 左侧（X负方向）
    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f, 1.0f, 0.0f,
    -0.5f,  0.5f, -0.5f, -1.0f,  0.0f,  0.0f, 1.0f, 1.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f, -0.5f, -1.0f,  0.0f,  0.0f, 0.0f, 1.0f,
    -0.5f, -0.5f,  0.5f, -1.0f,  0.0f,  0.0f, 0.0f, 0.0f,
    -0.5f,  0.5f,  0.5f, -1.0f,  0.0f,  0.0f, 1.0f, 0.0f,

    // 右侧（X正方向）
     0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f, 1.0f, 0.0f,
     0.5f, -0.5f,  0.5f,  1.0f,  0.0f,  0.0f, 0.0f, 0.0f,
     0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f, 0.0f, 1.0f,
     0.5f, -0.5f, -0.5f,  1.0f,  0.0f,  0.0f, 0.0f, 1.0f,
     0.5f,  0.5f, -0.5f,  1.0f,  0.0f,  0.0f, 1.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  1.0f,  0.0f,  0.0f, 1.0f, 0.0f,

    // 底部（Y负方向）
    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f, 0.0f, 1.0f,
     0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f, 1.0f, 1.0f,
     0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f, 1.0f, 0.0f,
     0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f, 1.0f, 0.0f,
    -0.5f, -0.5f,  0.5f,  0.0f, -1.0f,  0.0f, 0.0f, 0.0f,
    -0.5f, -0.5f, -0.5f,  0.0f, -1.0f,  0.0f, 0.0f, 1.0f,

    // 顶部（Y正方向）
    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f, 0.0f, 1.0f,
     0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f, 1.0f, 1.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f, 1.0f, 0.0f,
     0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f, 1.0f, 0.0f,
    -0.5f,  0.5f,  0.5f,  0.0f,  1.0f,  0.0f, 0.0f, 0.0f,
    -0.5f,  0.5f, -0.5f,  0.0f,  1.0f,  0.0f, 0.0f, 1.0f
};

//地面顶点数据
float groundVertices[] = {
    // 位置           // 法线
    -100.0f, -5.0f, -100.0f, 0.0f, 1.0f, 0.0f,
     100.0f, -5.0f, -100.0f, 0.0f, 1.0f, 0.0f,
     100.0f, -5.0f, 100.0f, 0.0f, 1.0f, 0.0f,
    -100.0f, -5.0f, 100.0f, 0.0f, 1.0f, 0.0f,
};
unsigned int groundIndices[] = { 0, 1, 2, 0, 2, 3 };

GLuint cubeVAO, cubeVBO;
GLuint shaderProgram;
GLuint groundVAO, groundVBO, groundEBO;
GLuint groundShaderProgram;

GLuint shadowShaderProgram;

int currentShadingModel = 0;
float rotationAngle = 0.0f;

void processInput(GLFWwindow* window);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void setupCube();
void renderUI();

std::vector<GLuint> textures;
std::vector<std::string> textureNames = { "stone", "Metal", "Fabric","porcelain"};

GLuint loadTexture(const char* path) {
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);

    // 加载参数设置
    stbi_set_flip_vertically_on_load(true);
    int width, height, nrChannels;
    unsigned char* data = stbi_load(path, &width, &height, &nrChannels, 0);

    if (data) {
        GLenum format = GL_RGB;
        if (nrChannels == 4) format = GL_RGBA;

        glTexImage2D(GL_TEXTURE_2D, 0, format,
            width, height, 0, format,
            GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);

        // 纹理参数
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    else {
        std::cout << "Failed to load texture: " << path << std::endl;
    }
    stbi_image_free(data);
    return textureID;
}

bool useTexture = false;
int selectedTexture = 0;

glm::mat4 computeShadowMatrix(glm::vec4 plane, glm::vec3 lightPos) {
    float d = glm::dot(plane, glm::vec4(lightPos, 1.0f));
    glm::mat4 shadowMat = glm::mat4(
        d - lightPos.x * plane.x, -lightPos.x * plane.y, -lightPos.x * plane.z, -lightPos.x * plane.w,
        -lightPos.y * plane.x, d - lightPos.y * plane.y, -lightPos.y * plane.z, -lightPos.y * plane.w,
        -lightPos.z * plane.x, -lightPos.z * plane.y, d - lightPos.z * plane.z, -lightPos.z * plane.w,
        -plane.x, -plane.y, -plane.z, d
    );
    return shadowMat;
}

void setupGround() {
    glGenVertexArrays(1, &groundVAO);
    glGenBuffers(1, &groundVBO);
    glGenBuffers(1, &groundEBO);

    glBindVertexArray(groundVAO);
    glBindBuffer(GL_ARRAY_BUFFER, groundVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(groundVertices), groundVertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, groundEBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(groundIndices), groundIndices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    glBindVertexArray(0);
}

int main()
{
    // 初始化GLFW
    glfwInit();
    GLFWwindow* window = glfwCreateWindow(800, 600, "OpenGL Shading Demo", NULL, NULL);
    glfwMakeContextCurrent(window);
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    // 设置ImGui
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    textures.push_back(loadTexture("textures/stone.jpg"));
    textures.push_back(loadTexture("textures/metal.jpg"));
    textures.push_back(loadTexture("textures/fabric.jpg"));
    textures.push_back(loadTexture("textures/porcelain.jpg"));

    // 编译着色器
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);

    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);

    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    GLuint shadowVert = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(shadowVert, 1, &shadowVertexShaderSource, NULL);
    glCompileShader(shadowVert);

    GLuint shadowFrag = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(shadowFrag, 1, &shadowFragmentShaderSource, NULL);
    glCompileShader(shadowFrag);

    setupCube();
    setupGround(); 

    
    // 开启深度测试
    glEnable(GL_DEPTH_TEST);

    
    GLuint groundVertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(groundVertexShader, 1, &groundVertexShaderSource, NULL);
    glCompileShader(groundVertexShader);

    GLuint groundFragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(groundFragmentShader, 1, &groundFragmentShaderSource, NULL);
    glCompileShader(groundFragmentShader);

    groundShaderProgram = glCreateProgram();
    glAttachShader(groundShaderProgram, groundVertexShader);
    glAttachShader(groundShaderProgram, groundFragmentShader);
    glLinkProgram(groundShaderProgram);

    shadowShaderProgram = glCreateProgram();
    glAttachShader(shadowShaderProgram, shadowVert);
    glAttachShader(shadowShaderProgram, shadowFrag);
    glLinkProgram(shadowShaderProgram);

  

    while (!glfwWindowShouldClose(window))
    {
        processInput(window);
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // 开始ImGui帧
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // 创建变换矩阵
        glm::mat4 model = glm::rotate(glm::mat4(1.0f), glm::radians(rotationAngle), glm::vec3(0.3f, 0.5f, 0.0f));
        glm::vec3 cameraPos = glm::vec3(2.0f, 2.0f, 3.0f);
        glm::mat4 view = glm::lookAt(cameraPos, glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 1.0f, 0.0f));

        glm::mat4 projection = glm::perspective(
            glm::radians(70.0f), // 适当减小视角避免变形
            800.0f / 600.0f,     // 确保宽高比正确
            0.1f,                // 近裁剪面
            500.0f               // 增加远裁剪面
        );


        // 设置光照相关参数
        glUniform3f(glGetUniformLocation(shaderProgram, "lightPos"), 1.5f, 1.0f, 1.5f);
        glUniform3f(glGetUniformLocation(shaderProgram, "viewPos"), cameraPos.x, cameraPos.y, cameraPos.z);
        glUniform3f(glGetUniformLocation(shaderProgram, "objectColor"), 0.2f, 0.6f, 0.6f);
        glUniform3f(glGetUniformLocation(shaderProgram, "lightColor"), 1.0f, 0.9f, 0.7f);


        // 1. 渲染地面
        glUseProgram(groundShaderProgram);
        glUniformMatrix4fv(glGetUniformLocation(groundShaderProgram, "view"), 1, GL_FALSE, &view[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(groundShaderProgram, "projection"), 1, GL_FALSE, &projection[0][0]);
        glUniform3f(glGetUniformLocation(groundShaderProgram, "color"), 0.5f, 0.5f, 0.5f);
        glBindVertexArray(groundVAO);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        // 2. 渲染阴影
        glUseProgram(shadowShaderProgram);
        glm::vec4 plane(0.0f, 1.0f, 0.0f, 0.0f); // y=0平面
        glm::vec3 lightPos(1.5f, 1.0f, 1.5f);
        glm::mat4 shadowProj = computeShadowMatrix(plane, lightPos);

        glUniformMatrix4fv(glGetUniformLocation(shadowShaderProgram, "model"), 1, GL_FALSE, &model[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(shadowShaderProgram, "shadowProj"), 1, GL_FALSE, &shadowProj[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(shadowShaderProgram, "view"), 1, GL_FALSE, &view[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(shadowShaderProgram, "projection"), 1, GL_FALSE, &projection[0][0]);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDepthMask(GL_FALSE); // 禁用深度写入

        glBindVertexArray(cubeVAO);
        glDrawArrays(GL_TRIANGLES, 0, 36);

        glDepthMask(GL_TRUE);
        glDisable(GL_BLEND);

        // 3. 渲染立方体本身
        glUseProgram(shaderProgram);

        // 设置Uniform变量
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "model"), 1, GL_FALSE, glm::value_ptr(model));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "view"), 1, GL_FALSE, glm::value_ptr(view));
        glUniformMatrix4fv(glGetUniformLocation(shaderProgram, "projection"), 1, GL_FALSE, glm::value_ptr(projection));
        glUniform1i(glGetUniformLocation(shaderProgram, "shadingModel"), currentShadingModel); // 设置着色模型
        glUniform1i(glGetUniformLocation(shaderProgram, "useTexture"), useTexture);

        if (useTexture) {
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, textures[selectedTexture]);
            glUniform1i(glGetUniformLocation(shaderProgram, "texture1"), 0);
        }

        // 绘制立方体
        glBindVertexArray(cubeVAO);
        glDrawArrays(GL_TRIANGLES, 0, 36);
        glBindVertexArray(0);

        // 渲染UI
        renderUI();

        // 渲染ImGui
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // 清理资源
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwTerminate();
    return 0;
}

void setupCube()
{
    glGenVertexArrays(1, &cubeVAO);
    glGenBuffers(1, &cubeVBO);

    glBindVertexArray(cubeVAO);
    glBindBuffer(GL_ARRAY_BUFFER, cubeVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // 位置属性
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)0);
    glEnableVertexAttribArray(0);
    // 法线属性
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(3 * sizeof(float)));
    glEnableVertexAttribArray(1);
    // 纹理坐标属性
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(6 * sizeof(float)));
    glEnableVertexAttribArray(2);
}




void renderUI()
{
    ImGui::Begin("Shading Control Panel");

    ImGui::Text("Shading Model:");
    ImGui::RadioButton("Lambert Shading", &currentShadingModel, 0);
    ImGui::RadioButton("Blinn-Phong Shading", &currentShadingModel, 1);
    ImGui::RadioButton("Phong Shading", &currentShadingModel, 2);

    ImGui::SliderFloat("Rotation", &rotationAngle, 0.0f, 360.0f);

    ImGui::Checkbox("Enable Texture", &useTexture);
    if (useTexture) {
        ImGui::Combo("Texture Type", &selectedTexture,
            [](void* data, int idx, const char** out_text) {
                *out_text = ((std::vector<std::string>*)data)->at(idx).c_str();
                return true;
            }, &textureNames, textureNames.size());
    }
    ImGui::End();
}

void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}